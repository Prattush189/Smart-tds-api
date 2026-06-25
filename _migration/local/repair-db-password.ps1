<#
  repair-db-password.ps1 - fix "master:null" / login 500 caused by the API and the
  PostgreSQL role `smarttds_app` disagreeing on the local DB password (PG error 28P01).

  THE CANONICAL LOCAL PASSWORD IS A FIXED CONSTANT: "Pass@123" (see DbOptions.LocalPassword
  + provision-local.ps1). The new API hardcodes it in Local mode and IGNORES appsettings;
  an OLD API exe still reads appsettings.Local.json. To heal a machine no matter which exe
  is installed (e.g. an upgrade that shipped new scripts but a stale exe), this script forces
  EVERYTHING to the constant: appsettings.Db.Password = Pass@123 AND the role = Pass@123,
  then restarts the API and verifies /health.

  Read-only-safe except: it rewrites one field in appsettings.Local.json, changes the DB role
  password, and restarts a service. Run ELEVATED (Run as administrator) - appsettings.Local.json
  is admin-locked.

    powershell -ExecutionPolicy Bypass -File "D:\SmartTDS\_migration\local\repair-db-password.ps1"
#>
[CmdletBinding()]
param(
  [string] $AppDir   = "",                 # auto-detected if empty (registry, then C:\ / D:\ SmartTDS)
  [int]    $PgPort   = 5433,
  [int]    $ApiPort  = 5080,
  [string] $SuperUser= "postgres",
  [string] $SuperPwd = "Pass@123"          # superuser is also set to the fixed value by provisioning
)
$ErrorActionPreference = "Stop"

# The single source of truth for the local DB password. Keep in sync with
# DbOptions.LocalPassword (API) and provision-local.ps1 ($AppPwd).
$LocalPassword = "Pass@123"

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) { Write-Host "ERROR: run this in an ELEVATED PowerShell (Run as administrator)." -ForegroundColor Red; exit 1 }

# ---- locate the install ----
function Find-AppDir {
  param([string] $Hint)
  $tries = @()
  if ($Hint) { $tries += $Hint }
  # registry (both 64- and 32-bit uninstall hives)
  $keys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )
  foreach ($k in $keys) {
    try {
      Get-ItemProperty $k -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "SmartTDS*" -and $_.InstallLocation } |
        ForEach-Object { $tries += $_.InstallLocation.TrimEnd('\') }
    } catch {}
  }
  $tries += @("D:\SmartTDS", "C:\SmartTDS")
  foreach ($t in ($tries | Select-Object -Unique)) {
    if ($t -and (Test-Path (Join-Path $t "api\appsettings.Local.json"))) { return $t }
  }
  return $null
}

$AppDir = Find-AppDir -Hint $AppDir
if (-not $AppDir) {
  Write-Host "Could not locate the SmartTDS install (no api\appsettings.Local.json under the registry path, D:\SmartTDS or C:\SmartTDS)." -ForegroundColor Red
  Write-Host "Re-run with -AppDir <install folder>, e.g.  -AppDir D:\SmartTDS" -ForegroundColor Yellow
  exit 1
}
Write-Host ("Install folder: {0}" -f $AppDir) -ForegroundColor Cyan

$cfg  = Join-Path $AppDir "api\appsettings.Local.json"
$psql = Join-Path $AppDir "pgsql\bin\psql.exe"
foreach ($p in @($cfg,$psql)) { if (-not (Test-Path $p)) { Write-Host "Not found: $p" -ForegroundColor Red; exit 1 } }

# 1) show what the API config currently holds (diagnostic only)
$raw = Get-Content $cfg -Raw
$cur = ($raw | ConvertFrom-Json).Db.Password
Write-Host ("appsettings Db.Password currently: length {0}{1}" -f $cur.Length,
            $(if ($cur -eq $LocalPassword) {" (already the fixed value)"} else {" (NOT the fixed value)"}))

# 2) force appsettings.Db.Password -> the fixed constant (heals an OLD exe that reads it)
if ($cur -ne $LocalPassword) {
  Write-Host (">> setting appsettings Db.Password -> {0}" -f $LocalPassword) -ForegroundColor Cyan
  $new = [regex]::Replace($raw, '("Password"\s*:\s*")[^"]*(")', ('${1}' + $LocalPassword + '${2}'))
  [System.IO.File]::WriteAllText($cfg, $new, (New-Object System.Text.UTF8Encoding $false))
} else {
  Write-Host "appsettings already correct - leaving it." -ForegroundColor DarkGray
}

# 3) BEFORE: does the role already accept the fixed password? (tells us if drift is the cause)
$env:PGPASSWORD = $LocalPassword
$before = & $psql -h 127.0.0.1 -p $PgPort -U smarttds_app -d masterdbtds -tAc "select 1" 2>&1
if ($LASTEXITCODE -eq 0) {
  Write-Host "Role ALREADY accepts the fixed password - drift is NOT the problem (API may just need a restart)." -ForegroundColor Yellow
} else {
  Write-Host "Role rejects the fixed password - will reset it now." -ForegroundColor Yellow
}

# 4) FIX: set the role password to the fixed constant
Write-Host (">> ALTER ROLE smarttds_app -> {0}" -f $LocalPassword) -ForegroundColor Cyan
$env:PGPASSWORD = $SuperPwd
$esc = $LocalPassword.Replace("'","''")
& $psql -h 127.0.0.1 -p $PgPort -U $SuperUser -d postgres -v ON_ERROR_STOP=1 -c "alter role smarttds_app password '$esc'" | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "ALTER ROLE failed. Is SmartTdsPg running on $PgPort, and is the superuser password '$SuperPwd'?" -ForegroundColor Red
  Write-Host "  (If the superuser password differs, re-run with -SuperPwd <password>.)" -ForegroundColor Yellow
  exit 1
}

# 5) restart the API and verify
Write-Host ">> restarting SmartTdsApi" -ForegroundColor Cyan
Restart-Service SmartTdsApi -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
$env:PGPASSWORD = $LocalPassword
$after = & $psql -h 127.0.0.1 -p $PgPort -U smarttds_app -d masterdbtds -tAc "select 1" 2>&1
Write-Host ("role login after fix: {0}" -f ($(if ($LASTEXITCODE -eq 0) {"OK"} else {"STILL FAILING: $after"})))

try {
  $h = Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/health" -f $ApiPort) -TimeoutSec 12
  if ($h.master) { Write-Host ("SUCCESS: /health master = {0}" -f $h.master) -ForegroundColor Green }
  else { Write-Host "Still master:null - the role login above must say OK first; if it does, check the API log in <AppDir>\Data\logs." -ForegroundColor Red }
} catch { Write-Host ("/health not reachable yet: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
