<#
  backup-local.ps1 — logical backup of the STANDALONE LOCAL PostgreSQL.
  Replaces the old SQL-Server FrmBackup (BACKUP DATABASE -> .bak), which does
  not work against PostgreSQL.

  Dumps masterdbtds + every smarttds<YY> DB with pg_dump custom format (-Fc),
  bundles them + a manifest into ONE timestamped zip, and prunes old zips so a
  rolling VERSION history is kept (per label).

  Output: <BackupRoot>\SmartTdsBackup_<label>_<yyyy_MM_dd_HH_mm_ss>.zip
  The full path of the new zip is written to stdout (last line) so callers
  (the API endpoint / scheduled task) can capture it.

  Usage:
    powershell -ExecutionPolicy Bypass -File backup-local.ps1                  # manual, keep 30
    powershell -ExecutionPolicy Bypass -File backup-local.ps1 -Label daily -Keep 30
    powershell -ExecutionPolicy Bypass -File backup-local.ps1 -BackupRoot D:\TdsBackups
#>
[CmdletBinding()]
param(
  [string] $InstallRoot = "",                        # data root (holds \backups). Default: auto-derived <AppDir>\Data
  [string] $PgBin,                                  # default <AppDir>\pgsql\bin (auto), else <InstallRoot>\pgsql\bin
  [int]    $Port      = 5433,
  [string] $SuperUser = "postgres",
  [string] $SuperPwd  = "Pass@123",                 # local-only superuser (FIXED across installs)
  [string] $BackupRoot,                             # default <InstallRoot>\backups
  [ValidateSet("manual","daily","auto","prerestore")]
  [string] $Label     = "manual",
  [int]    $Keep      = 30,                          # how many zips of THIS label to retain
  [string] $Licence   = ""                           # optional tag in the file name
)
$ErrorActionPreference = "Stop"

# Find the install <AppDir> (the folder holding api\SmartTdsApi.exe) the same way
# diagnose-local.ps1 does, so STANDALONE runs (and restore's safety backup) land in the
# CURRENT location <AppDir>\Data\backups + use pgsql at <AppDir>\pgsql\bin — instead of the
# legacy C:\ProgramData\SmartTds default. NOTE: pgsql and \Data have DIFFERENT parents, so
# we must derive each separately.
function Resolve-SmartTdsAppDir {
  foreach ($r in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
    if (-not (Test-Path $r)) { continue }
    foreach ($k in (Get-ChildItem $r -ErrorAction SilentlyContinue)) {
      $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
      if (-not $p -or -not $p.DisplayName -or -not $p.InstallLocation) { continue }
      if ($p.DisplayName -notlike '*SmartTDS*' -and $p.DisplayName -notlike '*Smart Tds*') { continue }
      $appDir = $p.InstallLocation.TrimEnd('\')
      if (Test-Path (Join-Path $appDir 'api\SmartTdsApi.exe')) { return $appDir }
    }
  }
  foreach ($d in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
    foreach ($name in @('SmartTDS','SmartTds')) {
      $appDir = Join-Path $d.Root $name
      if (Test-Path (Join-Path $appDir 'api\SmartTdsApi.exe')) { return $appDir }
    }
  }
  return $null
}
if (-not $InstallRoot -or -not $PgBin) {
  $appDir = Resolve-SmartTdsAppDir
  if ($appDir) {
    if (-not $PgBin) { $PgBin = Join-Path $appDir "pgsql\bin" }
    if (-not $InstallRoot) {
      $data = Join-Path $appDir "Data"
      if     (Test-Path $data)                                  { $InstallRoot = $data }
      elseif (Test-Path (Join-Path $env:ProgramData "SmartTds")) { $InstallRoot = Join-Path $env:ProgramData "SmartTds" }
      else                                                       { $InstallRoot = $data }
    }
  }
}
if (-not $InstallRoot) { $InstallRoot = Join-Path $env:ProgramData "SmartTds" }   # last-resort (legacy)
if (-not $PgBin)      { $PgBin      = Join-Path $InstallRoot "pgsql\bin" }        # last-resort (legacy layout)
if (-not $BackupRoot) { $BackupRoot = Join-Path $InstallRoot "backups" }
$pgDump = Join-Path $PgBin "pg_dump.exe"
$psql   = Join-Path $PgBin "psql.exe"
foreach ($t in @($pgDump,$psql)) { if (-not (Test-Path $t)) { throw "Missing tool: $t" } }
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
$env:PGPASSWORD = $SuperPwd

function Run-Native([string]$exe,[string[]]$a){
  $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  $out  = & $exe @a 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  return [pscustomobject]@{ Code=$code; Out=($out | Out-String) }
}

# ---- discover the SmartTds databases ----
$listSql = "select datname from pg_database where datname='masterdbtds' or datname like 'smarttds%' order by datname"
$r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d","postgres","-tAc",$listSql)
if ($r.Code -ne 0) { Write-Host $r.Out -ForegroundColor Red; throw "Cannot reach PostgreSQL on 127.0.0.1:$Port" }
$dbs = $r.Out -split "`r?`n" | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() }
if (-not $dbs) { throw "No SmartTds databases found." }

# ---- timestamped work dir ----
$stamp = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
$work  = Join-Path $env:TEMP ("sttds_bk_" + $stamp)
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
  $pgver = (Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d","postgres","-tAc","show server_version")).Out.Trim()
  foreach ($db in $dbs) {
    Write-Host "  dumping $db ..." -ForegroundColor Cyan
    $d = Run-Native $pgDump @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-Fc","-f",(Join-Path $work "$db.dump"))
    if ($d.Code -ne 0) { Write-Host $d.Out -ForegroundColor Red; throw "pg_dump failed for $db" }
  }
  # manifest
  $manifest = [ordered]@{
    product="SmartTds"; created=$stamp; label=$Label; licence=$Licence
    pg_server_version=$pgver; databases=$dbs; format="custom (pg_dump -Fc)"
  }
  ($manifest | ConvertTo-Json -Depth 5) | Set-Content -Path (Join-Path $work "manifest.json") -Encoding utf8

  # ---- one zip ----
  $tag = if ($Licence) { ($Licence -replace '[^A-Za-z0-9_]','') + "_" } else { "" }
  $zip = Join-Path $BackupRoot ("SmartTdsBackup_{0}{1}_{2}.zip" -f $tag,$Label,$stamp)
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory($work, $zip)
  Write-Host "  -> $zip" -ForegroundColor Green
}
finally { Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue }

# ---- record where/when in applicationparams (backupLoc + lastBackup) ----
# The desktop's Backup/Restore screen reads these to show the folder + last-backup date.
# Best-effort: a failure here must never fail the backup itself.
try {
  $locEsc = $BackupRoot -replace "'","''"
  # InvariantCulture: in a .NET format string "/" means "the culture's separator",
  # and en-IN renders that as "-" — the app's canonical date format is dd/MM/yyyy.
  $today  = (Get-Date).ToString("dd/MM/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
  $recSql = "update applicationparams set value='$locEsc' where name='backupLoc';" +
            "insert into applicationparams(name,value) select 'backupLoc','$locEsc' where not exists (select 1 from applicationparams where name='backupLoc');" +
            "update applicationparams set value='$today' where name='lastBackup';" +
            "insert into applicationparams(name,value) select 'lastBackup','$today' where not exists (select 1 from applicationparams where name='lastBackup');"
  $rec = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d","masterdbtds","-c",$recSql)
  if ($rec.Code -ne 0) { Write-Host "  (warn) could not record backupLoc/lastBackup: $($rec.Out)" -ForegroundColor Yellow }
} catch { Write-Host "  (warn) could not record backupLoc/lastBackup: $($_.Exception.Message)" -ForegroundColor Yellow }

# ---- retention: keep the newest $Keep zips of THIS label ----
if ($Keep -gt 0) {
  $old = Get-ChildItem $BackupRoot -Filter ("SmartTdsBackup_*{0}_*.zip" -f $Label) -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep
  foreach ($f in $old) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue; Write-Host "  pruned old: $($f.Name)" -ForegroundColor DarkGray }
}

# last line = the new zip path (callers capture this)
$zip
