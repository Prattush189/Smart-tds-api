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
  [switch] $PurgeData,                            # on uninstall, delete the PG data (KEEPS the backups\ folder)
  [switch] $RestoreLatestIfFound,                 # on install, if a backup exists and the DB is fresh, restore the newest
  [string] $SupportUrl = "",                      # vendor support registry base URL (https only); empty = don't report
  [string] $SupportKey = ""                       # shared key the registry endpoint expects (X-Support-Key)
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
    # The whole uninstall is best-effort and must NEVER fail the MSI action.
    $ErrorActionPreference = 'SilentlyContinue'
    Say "Removing SmartTds..."

    # 1) STOP + KILL FIRST — this unlocks the data + pgsql files regardless of service
    #    state and frees the PG port for any later reinstall. Order matters:
    #    a) Stop-Service: the clean path while the services still exist.
    #    b) Kill whatever LISTENS on the PG port: catches an orphaned postmaster whose
    #       service entry is already gone — Get-Process .Path is NULL for such SYSTEM
    #       processes, so the old path-filtered kill silently missed it and the next
    #       install died with "could not bind 127.0.0.1:5433".
    #    c) Path-filtered kill as the final sweep.
    try {
      Stop-Service SmartTdsPg, SmartTdsApi -Force -ErrorAction SilentlyContinue
      $portOwners = @(Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue |
                      Select-Object -ExpandProperty OwningProcess -Unique)
      foreach ($ownerPid in $portOwners) { Stop-Process -Id $ownerPid -Force -ErrorAction SilentlyContinue }
      Get-Process postgres -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Path -or $_.Path -like "$AppDir*" -or $_.Path -like "$DataRoot*" } |
        Stop-Process -Force -ErrorAction SilentlyContinue
      Get-Process SmartTdsApi -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    } catch { Say ("process cleanup warning (ignored): " + $_.Exception.Message) "Yellow" }
    Start-Sleep -Milliseconds 500

    # 2) remove the services (processes are already dead, so this is clean)
    try { & (Join-Path $here "install-service.ps1") -PgBin $pgBin -Uninstall }
    catch { Say ("uninstall warning (ignored): " + $_.Exception.Message) "Yellow" }

    if ($PurgeData) {
      Say "Purging PostgreSQL data under $DataRoot (KEEPING backups\)" "Yellow"
      # Keep backups (recovery). machineid.dat is NO LONGER preserved: the machine-id is
      # now derived from the OS (MachineGuid / machine-id), so it's recomputed on the same
      # box regardless of the file — keeping a stale/copied file would be misleading.
      Get-ChildItem -LiteralPath $DataRoot -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'backups' } |
        ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    } else {
      Say "Done. PostgreSQL data + backups left intact under $DataRoot." "Green"
    }

    # MSI removes the app files it installed, but leaves any modified/runtime files
    # (patched appsettings, logs). We can't delete our own running folder synchronously,
    # so schedule a DETACHED cleanup that waits for MSI + this script to finish, then
    # removes ONLY the SmartTds-owned subfolders (api, _migration, pgsql). Anything else
    # the user keeps under AppDir (e.g. their desktop .exe) is left untouched.
    try {
      $cl = Join-Path $env:TEMP "_sttds_cleanup.cmd"
      Set-Content -Path $cl -Encoding ascii -Value @"
@echo off
ping 127.0.0.1 -n 12 >nul
rmdir /s /q "$AppDir\api"
rmdir /s /q "$AppDir\_migration"
rmdir /s /q "$AppDir\pgsql"
schtasks /Delete /TN SmartTdsCleanup /F
"@
      & schtasks.exe /Create /TN SmartTdsCleanup /TR "`"$cl`"" /SC ONCE /ST 23:59 /RU SYSTEM /RL HIGHEST /F | Out-Null
      & schtasks.exe /Run /TN SmartTdsCleanup | Out-Null
    } catch { }

    # NOTE: do NOT Stop-Transcript here — the outer finally does it. Calling it twice
    # raises a terminating error in the finally (under EAP=Stop) -> powershell exits 1
    # -> MSI falsely reports the uninstall action failed even though cleanup succeeded.
    exit 0
  }

  # 1) provision DB (creates cluster on :PgPort, the 3 DBs, admin user; patches API appsettings.Local.json)
  # Defensive: a previous failed install/uninstall can leave an orphaned postmaster
  # holding the PG port (it survived the old path-filtered kill because .Path is NULL
  # on such SYSTEM processes). Clear the port before provisioning or pg_ctl start dies
  # with "could not bind 127.0.0.1:<port>".
  try {
    Stop-Service SmartTdsPg, SmartTdsApi -Force -ErrorAction SilentlyContinue
    $stalePids = @(Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue |
                   Select-Object -ExpandProperty OwningProcess -Unique)
    foreach ($stalePid in $stalePids) {
      Say "Killing stale process $stalePid holding port $PgPort" "Yellow"
      Stop-Process -Id $stalePid -Force -ErrorAction SilentlyContinue
    }
    if ($stalePids.Count -gt 0) { Start-Sleep -Milliseconds 800 }
  } catch { }

  # Delete any leftover machineid.dat — the machine-id is OS-derived now (MachineGuid /
  # /etc/machine-id), so the file is just a cache. Removing it on install guarantees a
  # cloned/copied ProgramData can't carry another machine's id; the API regenerates the
  # correct one (this box's) on first start.
  try { Remove-Item (Join-Path $DataRoot "machineid.dat") -Force -ErrorAction SilentlyContinue } catch { }

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

  # 3b) restore the newest backup onto a FRESH install (e.g. after a -PurgeData
  #     reinstall that kept backups\). Skips if the DB already has data (repair install).
  if ($RestoreLatestIfFound) {
    $backupsDir = Join-Path $DataRoot "backups"
    $latest = Get-ChildItem $backupsDir -Filter "SmartTdsBackup_*.zip" -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
      $env:PGPASSWORD = "postgres"
      $cnt = & (Join-Path $pgBin "psql.exe") -h 127.0.0.1 -p $PgPort -U postgres -d masterdbtds -tAc "select count(*) from assessee" 2>$null
      if (("$cnt".Trim()) -eq "0") {
        Say ("== restoring most recent backup: " + $latest.Name + " ==")
        & (Join-Path $here "restore-local.ps1") -BackupZip $latest.FullName -InstallRoot $DataRoot `
            -PgBin $pgBin -Port $PgPort -Force -NoSafetyBackup
      } else {
        Say "  (database already has data - skipping auto-restore)" "Yellow"
      }
    } else {
      Say "  (no backup found in $backupsDir - nothing to restore)" "Yellow"
    }
  }

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

  # FINAL role<->config password sync — runs LAST, after the MSI's file copies, the
  # provision patch and the restore, so whatever appsettings.Local.json ends up on disk
  # is what the role password matches. Root cause this heals: the MSI lays down the
  # PACKAGED appsettings (e.g. a stale dist\api build) with an old password while
  # provisioning set the role to a fresh random one -> every API call died with
  # "28P01 password authentication failed". Re-read the file, ALTER ROLE to its value,
  # bounce the API so it reconnects.
  try {
    $cfgFinal = Join-Path $apiDir "appsettings.Local.json"
    if (Test-Path $cfgFinal) {
      $apiPwFinal = (Get-Content $cfgFinal -Raw | ConvertFrom-Json).Db.Password
      if ($apiPwFinal) {
        $env:PGPASSWORD = "postgres"
        & (Join-Path $pgBin "psql.exe") -h 127.0.0.1 -p $PgPort -U postgres -d postgres `
          -c ("alter role smarttds_app password '" + $apiPwFinal.Replace("'","''") + "'") | Out-Null
        Restart-Service SmartTdsApi -ErrorAction SilentlyContinue
        Say "Final role<->config password sync done."
      }
    }
  } catch { Say ("final password sync warning (ignored): " + $_.Exception.Message) "Yellow" }

  # ---- LOCK DOWN the data tree (security) ----
  # By default everything under C:\ProgramData is readable by all interactive users, so a
  # standard (non-admin) user could read api\appsettings.Local.json — which holds the DB
  # password AND the JWT signing key (= forge any token) — and could tamper with the API
  # exe that runs as LocalSystem (SYSTEM code execution). Restrict the whole tree to
  # SYSTEM + Administrators only. This also protects the install transcript + backups
  # (full DB dumps with all PII) at rest. The API service (LocalSystem) and admins keep
  # full access; nothing else needs it (the desktop talks to the API over HTTP).
  try {
    & icacls.exe "$DataRoot" /inheritance:r /grant:r "SYSTEM:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" /T /C /Q | Out-Null
    Say "Locked down $DataRoot to SYSTEM + Administrators."
  } catch { Say ("ACL hardening warning (ignored): " + $_.Exception.Message) "Yellow" }

  # ---- Best-effort: report this install's DB creds to the central vendor registry ----
  # Lets support recover a client's PostgreSQL credentials remotely. OFF unless -SupportUrl
  # (+ -SupportKey) is configured; REQUIRES https so creds never travel in clear text; and
  # NEVER blocks the install (no internet / endpoint down -> silently skipped). The endpoint
  # stores the creds AES-encrypted and is itself disabled unless the VPS sets Support__Key.
  if ($SupportUrl) {
    if ($SupportUrl -notlike 'https://*') {
      Say "Support registry skipped: -SupportUrl must be https (refusing to send DB creds over http)." "Yellow"
    } else {
      try {
        # Match the API's machine-id (SHA256('SmartTds.MachineId.v2|winguid:'+MachineGuid)[..16]).
        $guid = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction Stop).MachineGuid
        $sha  = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                  [System.Text.Encoding]::UTF8.GetBytes("SmartTds.MachineId.v2|winguid:$guid"))
        $mid  = ([System.BitConverter]::ToString($sha) -replace '-','').Substring(0,16)
        $appPw = $null
        try { $appPw = (Get-Content (Join-Path $apiDir "appsettings.Local.json") -Raw | ConvertFrom-Json).Db.Password } catch {}
        $payload = @{
          machineId   = $mid
          machineName = $env:COMPUTERNAME
          dbPort      = $PgPort
          superUser   = "postgres"
          superPwd    = "postgres"     # local superuser pw (see provision-local.ps1)
          appRoleUser = "smarttds_app"
          appRolePwd  = $appPw
          appVersion  = ""
        } | ConvertTo-Json -Compress
        Invoke-RestMethod -Method Post -Uri ($SupportUrl.TrimEnd('/') + '/api/support/install') `
          -Headers @{ 'X-Support-Key' = $SupportKey } -ContentType 'application/json' `
          -Body $payload -TimeoutSec 15 | Out-Null
        Say "Reported DB creds to the support registry."
      } catch { Say ("support registry skipped (non-fatal): " + $_.Exception.Message) "Yellow" }
    }
  }

  Say "`nINSTALL COMPLETE." "Green"
  Say ("  API   : http://127.0.0.1:{0}/health  (LAN: http://<server-ip>:{0})" -f $ApiPort)
  Say ("  Login : {0} / (the admin password set during install)   (enter your Licence Key on the login screen - binds on first login)" -f $AdminUser)
}
finally { try { Stop-Transcript | Out-Null } catch { } }
