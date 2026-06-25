<#
  install-service.ps1 — register the local SmartTds API (and PostgreSQL) as
  auto-start Windows services. Run ELEVATED (the Advanced Installer custom action
  runs as admin). Idempotent: re-running updates existing services.

  EXAMPLES
    # after publish-local.ps1 + provision-local.ps1
    pwsh _migration\local\install-service.ps1 `
      -ApiExe   C:\ProgramData\SmartTds\api\SmartTdsApi.exe `
      -PgBin    C:\ProgramData\SmartTds\pgsql\bin `
      -DataDir  C:\ProgramData\SmartTds\data `
      -Port 5080 -LanFirewall

    # remove everything
    pwsh _migration\local\install-service.ps1 -Uninstall
#>
[CmdletBinding()]
param(
  [string] $ApiExe,                                  # path to published SmartTdsApi.exe
  [string] $PgBin,                                   # ...\pgsql\bin (to register PG as a service)
  [string] $DataDir = (Join-Path $env:ProgramData "SmartTds\data"),
  [int]    $PgPort  = 5433,
  [int]    $Port    = 5080,                          # API listen port (LAN firewall rule)
  [string] $ApiServiceName = "SmartTdsApi",
  [string] $PgServiceName  = "SmartTdsPg",
  [switch] $LanFirewall,                             # open the API port for the office LAN
  [string] $BackupTime     = "20:00",               # daily auto-backup time (HH:mm)
  [int]    $BackupKeep     = 30,                     # rolling daily backups to retain
  [switch] $NoBackupTask,                            # skip registering the daily backup task
  [string] $BackupTaskName = "SmartTds Daily Backup",
  [switch] $Uninstall
)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Native tools (sc.exe / pg_ctl / netsh) write warnings to stderr; under EAP=Stop
# PowerShell 5.1 turns that into a TERMINATING NativeCommandError. Use Continue so
# best-effort cleanup never aborts; install-path failures use explicit `throw`
# (which terminates regardless of EAP) + $LASTEXITCODE checks.
$ErrorActionPreference = "Continue"
function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

function Remove-Svc($name){
  try {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc){ Say "Removing service $name"; if ($svc.Status -ne 'Stopped'){ Stop-Service $name -Force -ErrorAction SilentlyContinue }
      & sc.exe delete $name | Out-Null }
  } catch { Say ("  (could not remove $($name): " + $_.Exception.Message + ")") "Yellow" }
}

if ($Uninstall) {
  # Best-effort: never let cleanup failures block an uninstall.
  try {
    Remove-Svc $ApiServiceName
    # Stop+delete the PG service FIRST: running pg_ctl unregister while the service is
    # still running deletes the SCM entry but leaves the postmaster process alive and
    # holding the port — Remove-Svc then finds no service and the orphan blocks the
    # next install ("could not bind 127.0.0.1:5433"). unregister stays as a fallback
    # for a registration Remove-Svc could not see.
    Remove-Svc $PgServiceName
    if ($PgBin) { $pgctl = Join-Path $PgBin "pg_ctl.exe"; if (Test-Path $pgctl) { & $pgctl unregister -N $PgServiceName 2>$null | Out-Null } }
    & netsh advfirewall firewall delete rule name="SmartTds API ($Port)" 2>$null | Out-Null
    & schtasks.exe /Delete /TN "$BackupTaskName" /F 2>$null | Out-Null
    Say "Uninstalled." "Green"
  } catch { Say ("uninstall cleanup warning (ignored): " + $_.Exception.Message) "Yellow" }
  exit 0
}

# --- PostgreSQL service (so the DB survives reboot) ---
if ($PgBin) {
  $pgctl = Join-Path $PgBin "pg_ctl.exe"
  if (-not (Test-Path $pgctl)) { throw "pg_ctl.exe not found in $PgBin" }
  if (Get-Service -Name $PgServiceName -ErrorAction SilentlyContinue) {
    Say "PG service $PgServiceName already present" "Yellow"
  } else {
    Say "Registering PostgreSQL service $PgServiceName (port $PgPort)"
    & $pgctl register -N $PgServiceName -D $DataDir -S auto -o "-p $PgPort"
    if ($LASTEXITCODE -ne 0) { throw "pg_ctl register failed ($LASTEXITCODE)" }
  }
  Start-Service $PgServiceName -ErrorAction SilentlyContinue
}

# --- API service (self-contained exe; --environment Local picks appsettings.Local.json) ---
if ($ApiExe) {
  if (-not (Test-Path $ApiExe)) { throw "ApiExe not found: $ApiExe" }
  $bin = '"{0}" --environment Local --urls http://0.0.0.0:{1}' -f $ApiExe,$Port
  if (Get-Service -Name $ApiServiceName -ErrorAction SilentlyContinue) {
    Say "Updating API service $ApiServiceName"
    & sc.exe config $ApiServiceName binPath= $bin start= auto | Out-Null
  } else {
    Say "Creating API service $ApiServiceName (port $Port)"
    & sc.exe create $ApiServiceName binPath= $bin start= auto DisplayName= "SmartTds Local API" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "sc create failed ($LASTEXITCODE)" }
  }
  # The API needs PostgreSQL: make Windows start PG first and not consider the API
  # "started" until PG is up (prevents the API running with no DB -> /health master:null
  # at first login, e.g. after a reboot).
  if ($PgBin) { & sc.exe config $ApiServiceName depend= $PgServiceName | Out-Null }
  & sc.exe failure $ApiServiceName reset= 60 actions= restart/5000/restart/5000/restart/5000 | Out-Null
  Restart-Service $ApiServiceName -ErrorAction SilentlyContinue
  Start-Service   $ApiServiceName -ErrorAction SilentlyContinue
}

# --- daily auto-backup scheduled task (runs even if the app is never opened) ---
if (-not $NoBackupTask) {
  $bscript = Join-Path $here "backup-local.ps1"
  if (Test-Path $bscript) {
    Say "Registering daily backup task '$BackupTaskName' at $BackupTime"
    $tr = 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "{0}" -Label daily -Keep {1} -Port {2}' -f $bscript,$BackupKeep,$PgPort
    & schtasks.exe /Create /TN "$BackupTaskName" /TR $tr /SC DAILY /ST $BackupTime /RU SYSTEM /RL HIGHEST /F | Out-Null
    if ($LASTEXITCODE -ne 0) { Say "  (could not register backup task - $LASTEXITCODE)" "Yellow" }
  } else { Say "  (backup-local.ps1 not found next to this script - skip task)" "Yellow" }
}

# --- optional: open the API port to the office LAN (single-PC installs don't need this) ---
if ($LanFirewall) {
  Say "Adding firewall rule for API port $Port (LAN)"
  & netsh advfirewall firewall delete rule name="SmartTds API ($Port)" 2>$null | Out-Null
  & netsh advfirewall firewall add rule name="SmartTds API ($Port)" dir=in action=allow protocol=TCP localport=$Port profile=private | Out-Null
}

Say "`nDONE." "Green"
Say ("  API service: {0}  (http://127.0.0.1:{1}/health)" -f $ApiServiceName,$Port)
if ($PgBin) { Say ("  PG  service: {0}  (127.0.0.1:{1})" -f $PgServiceName,$PgPort) }
