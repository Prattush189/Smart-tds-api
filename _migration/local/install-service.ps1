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
  [switch] $Uninstall
)
$ErrorActionPreference = "Stop"
function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

function Remove-Svc($name){
  $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
  if ($svc){ Say "Removing service $name"; if ($svc.Status -ne 'Stopped'){ Stop-Service $name -Force -ErrorAction SilentlyContinue }
    & sc.exe delete $name | Out-Null }
}

if ($Uninstall) {
  Remove-Svc $ApiServiceName
  if ($PgBin) { $pgctl = Join-Path $PgBin "pg_ctl.exe"; if (Test-Path $pgctl) { & $pgctl unregister -N $PgServiceName 2>$null | Out-Null } }
  Remove-Svc $PgServiceName
  & netsh advfirewall firewall delete rule name="SmartTds API ($Port)" 2>$null | Out-Null
  Say "Uninstalled." "Green"; return
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
  & sc.exe failure $ApiServiceName reset= 60 actions= restart/5000/restart/5000/restart/5000 | Out-Null
  Restart-Service $ApiServiceName -ErrorAction SilentlyContinue
  Start-Service   $ApiServiceName -ErrorAction SilentlyContinue
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
