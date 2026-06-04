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

  EXAMPLE (what the installer runs):
    powershell -ExecutionPolicy Bypass -File "[APPDIR]_migration\local\install-local.ps1" `
      -AppDir "[APPDIR]" -LicenceKey "[LICENCEKEY]" -AdminPwd "[ADMINPWD]" -Lan
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string] $AppDir,
  [string] $LicenceKey = "DEMO123456",          # the firm's REAL Licence Key (ServiceUL); also the admin user's prodkey
  [string] $AdminUser  = "admin",
  [string] $AdminPwd   = "Admin@123",
  [int]    $ApiPort    = 5080,
  [int]    $PgPort     = 5433,
  [string] $DataRoot   = (Join-Path $env:ProgramData "SmartTds"),
  [switch] $Lan,                                  # open the API port for the office LAN
  [switch] $Uninstall
)
$ErrorActionPreference = "Stop"
function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

$AppDir  = $AppDir.TrimEnd('\')
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
    & (Join-Path $here "install-service.ps1") -PgBin $pgBin -Uninstall
    Say "Done. (PostgreSQL data left intact under $dataDir)" "Green"
    return
  }

  # 1) provision DB (creates cluster on :PgPort, the 3 DBs, admin user; patches API appsettings.Local.json)
  Say "== provisioning database =="
  & (Join-Path $here "provision-local.ps1") `
      -InstallRoot $DataRoot -PgBin $pgBin -Port $PgPort `
      -ApiDir $apiDir -LicenceKey $LicenceKey -AdminUser $AdminUser -AdminPwd $AdminPwd

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
  Say ("  Login : {0} / {1}   (Licence Key: {2})" -f $AdminUser,$AdminPwd,$LicenceKey.ToUpper())
}
finally { Stop-Transcript | Out-Null }
