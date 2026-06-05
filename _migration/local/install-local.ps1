<#
  install-local.ps1 — ONE orchestrator the Advanced Installer "Database" project
  calls as a post-install custom action. Does the whole local-server setup:
    1. provision a private PostgreSQL + the 3 DBs + a bootstrap admin user
    2. register PostgreSQL + the API as auto-start Windows services
    3. point THIS machine's desktop app at the local API (http://127.0.0.1:<ApiPort>)

  Runs ELEVATED (installer custom actions are admin). All paths are derived from
  -AppDir so it works wherever the user installs.

  Expected layout under -AppDir (laid down by the installer):
    <AppDir>\api\SmartTdsApi.exe ...           (publish-local.ps1 output)
    <AppDir>\pgsql\bin\...                       (portable PostgreSQL binaries)
    <AppDir>\_migration\local\*.ps1              (these scripts)
    <AppDir>\_migration\phase1\pg\*.sql          (schema)
    <AppDir>\_migration\phase5\*.sql             (licensing/grants)
    <AppDir>\SmartTdsWinUI.exe.Config            (the desktop app config, optional)

  EXAMPLE (what the installer runs - NO licence key; the firm enters it at first login).
  Do NOT pass -AppDir from MSI: [APPDIR] ends in '\' and "[APPDIR]" becomes an escaped
  quote. The script derives AppDir from its own location instead.
    powershell -ExecutionPolicy Bypass -File "[APPDIR]_migration\local\install-local.ps1" -AdminPwd "[ADMINPWD]" -Lan
#>
[CmdletBinding()]
param(
  [string] $AppDir,                                # optional; defaults to this script's own location (avoids MSI [APPDIR] quoting issues)
  [string] $AdminUser  = "admin",
  [string] $AdminPwd   = "admin",
  [int]    $ApiPort    = 5080,
  [int]    $PgPort     = 5433,
  [string] $DataRoot   = (Join-Path $env:ProgramData "SmartTds"),
  [switch] $Lan,                                  # open the API port for the office LAN
  [switch] $Uninstall,
  [switch] $PurgeData                             # on uninstall, ALSO delete the PG data + backups (full wipe)
)
$ErrorActionPreference = "Stop"
function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

# ALWAYS derive AppDir from THIS script's own folder. This script lives at
# <AppDir>\_migration\local\install-local.ps1, so AppDir is two levels up.
# We deliberately IGNORE any -AppDir passed in: MSI's [APPDIR] ends in '\', which
# when quoted ("[APPDIR]") becomes an escaped quote (\") and corrupts the arguments.
# Deriving from the script location is 100% reliable and quoting-proof.
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$AppDir = Split-Path -Parent (Split-Path -Parent $scriptDir)   # ...\_migration\local -> ...\_migration -> APPDIR

$here    = Join-Path $AppDir "_migration\local"
$pgBin   = Join-Path $AppDir "pgsql\bin"
$apiDir  = Join-Path $AppDir "api"
$dataDir = Join-Path $DataRoot "data"
$logDir  = Join-Path $DataRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir "install-local.log") -Append | Out-Null

try {
  if ($Uninstall) {
    Say "Removing SmartTds services..."
    # Best-effort: an uninstall custom action must NEVER fail (or it blocks removal).
    try { & (Join-Path $here "install-service.ps1") -PgBin $pgBin -Uninstall }
    catch { Say ("uninstall warning (ignored): " + $_.Exception.Message) "Yellow" }

    # Kill any lingering processes so (a) the app can't keep serving logins after
    # uninstall and (b) MSI can delete the api\ / pgsql\ files (postgres.exe locks them).
    try {
      Get-Process postgres -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and ($_.Path -like "$AppDir*" -or $_.Path -like "$DataRoot*") } |
        Stop-Process -Force -ErrorAction SilentlyContinue
      Get-Process SmartTdsApi -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    } catch { Say ("process cleanup warning (ignored): " + $_.Exception.Message) "Yellow" }

    if ($PurgeData) {
      Say "Purging PostgreSQL data + backups under $DataRoot" "Yellow"
      Remove-Item -Recurse -Force $DataRoot -ErrorAction SilentlyContinue
    } else {
      Say "Done. PostgreSQL data + backups left intact under $DataRoot (pass -PurgeData for a full wipe)." "Green"
    }
    Stop-Transcript | Out-Null
    exit 0
  }

  # 1) provision DB (creates cluster on :PgPort, the 3 DBs, admin user; patches API appsettings.Local.json)
  Say "== provisioning database =="
  & (Join-Path $here "provision-local.ps1") `
      -InstallRoot $DataRoot -PgBin $pgBin -Port $PgPort `
      -ApiDir $apiDir -AdminUser $AdminUser -AdminPwd $AdminPwd

  # 1b) apply any pending schema migrations to existing/just-created DBs (PG still running)
  Say "== applying schema migrations =="
  & (Join-Path $here "migrate-local.ps1") -InstallRoot $DataRoot -PgBin $pgBin -Port $PgPort

  # 2) stop the provisioning-started server so it can be re-owned by a Windows service (same data dir)
  Say "== handing PostgreSQL over to a service =="
  $pgctl = Join-Path $pgBin "pg_ctl.exe"
  if (Test-Path $pgctl) { & $pgctl -D $dataDir -m fast stop }

  # 3) register PostgreSQL + API as auto-start services and start them
  Say "== installing services =="
  & (Join-Path $here "install-service.ps1") `
      -ApiExe (Join-Path $apiDir "SmartTdsApi.exe") -PgBin $pgBin -DataDir $dataDir `
      -PgPort $PgPort -Port $ApiPort -LanFirewall:$Lan

  # 4) point THIS machine's desktop app at the local API
  $cfg = Join-Path $AppDir "SmartTdsWinUI.exe.Config"
  if (Test-Path $cfg) {
    Say "== pointing desktop app at http://127.0.0.1:$ApiPort =="
    [xml]$x = Get-Content $cfg
    $app = $x.configuration.appSettings
    function SetKey($k,$v){
      $n = $app.add | Where-Object { $_.key -eq $k }
      if ($n) { $n.value = $v } else {
        $e = $x.CreateElement("add"); $e.SetAttribute("key",$k); $e.SetAttribute("value",$v); $app.AppendChild($e) | Out-Null }
    }
    SetKey "UseApi" "true"
    SetKey "ApiBaseUrl" ("http://127.0.0.1:{0}" -f $ApiPort)
    $x.Save($cfg)
  } else { Say "  (no SmartTdsWinUI.exe.Config at $AppDir - skip; client PCs set ApiBaseUrl to the server's LAN IP)" "Yellow" }

  Say "`nINSTALL COMPLETE." "Green"
  Say ("  API   : http://127.0.0.1:{0}/health  (LAN: http://<server-ip>:{0})" -f $ApiPort)
  Say ("  Login : {0} / {1}   (enter your Licence Key on the login screen - binds on first login)" -f $AdminUser,$AdminPwd)
}
finally { Stop-Transcript | Out-Null }
