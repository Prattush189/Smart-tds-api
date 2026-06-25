<#
  restore-local.ps1 - restore a SmartTds backup zip (made by backup-local.ps1)
  into the STANDALONE LOCAL PostgreSQL.

  Steps (per database in the zip):
    1. (unless -NoSafetyBackup) take a fresh 'prerestore' backup first
    2. stop the API Windows service so nothing holds connections
    3. terminate connections, DROP + CREATE the database
    4. pg_restore the custom-format dump (--no-owner)
    5. re-apply the least-privilege grants so smarttds_app keeps working
    6. restart the API service

  DESTRUCTIVE: replaces the named databases. Requires -Force (or confirms).

  Usage:
    powershell -ExecutionPolicy Bypass -File restore-local.ps1 -BackupZip "C:\...\SmartTdsBackup_manual_2026_06_04_18_00_00.zip" -Force
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string] $BackupZip,
  [string] $InstallRoot = (Join-Path $env:ProgramData "SmartTds"),
  [string] $PgBin,                                  # default <InstallRoot>\pgsql\bin
  [int]    $Port      = 5433,
  [string] $SuperUser = "postgres",
  [string] $SuperPwd  = "Pass@123",
  [string] $ServiceName = "SmartTdsApi",
  [string] $GrantsSql,                              # default ..\phase5\01_least_privilege_role.sql
  [switch] $NoSafetyBackup,
  [switch] $Force
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $PgBin)     { $PgBin     = Join-Path $InstallRoot "pgsql\bin" }
if (-not $GrantsSql) { $GrantsSql = Join-Path $here "..\phase5\01_least_privilege_role.sql" }
$psql      = Join-Path $PgBin "psql.exe"
$pgRestore = Join-Path $PgBin "pg_restore.exe"
foreach ($t in @($psql,$pgRestore)) { if (-not (Test-Path $t)) { throw "Missing tool: $t" } }
if (-not (Test-Path $BackupZip)) { throw "Backup zip not found: $BackupZip" }
$env:PGPASSWORD = $SuperPwd

function Run-Native([string]$exe,[string[]]$a){
  $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  $out  = & $exe @a 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  return [pscustomobject]@{ Code=$code; Out=($out | Out-String) }
}
function Psql-Postgres([string]$sql){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d","postgres","-v","ON_ERROR_STOP=1","-c",$sql)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "psql failed: $sql" }
}

# ---- extract ----
$work = Join-Path $env:TEMP ("sttds_rs_" + (Get-Date -Format "yyyyMMddHHmmss"))
New-Item -ItemType Directory -Force -Path $work | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($BackupZip, $work)
$dumps = Get-ChildItem $work -Filter *.dump
if (-not $dumps) { Remove-Item $work -Recurse -Force; throw "No .dump files inside the zip." }
$dbNames = $dumps | ForEach-Object { $_.BaseName }

if (-not $Force) {
  Write-Host "About to OVERWRITE these databases: $($dbNames -join ', ')" -ForegroundColor Yellow
  $ans = Read-Host "Type RESTORE to proceed"
  if ($ans -ne "RESTORE") { Remove-Item $work -Recurse -Force; Write-Host "Aborted."; return }
}

try {
  if (-not $NoSafetyBackup) {
    Write-Host ">> safety backup (label=prerestore)" -ForegroundColor Cyan
    & (Join-Path $here "backup-local.ps1") -InstallRoot $InstallRoot -PgBin $PgBin -Port $Port `
        -SuperUser $SuperUser -SuperPwd $SuperPwd -Label prerestore -Keep 10 | Out-Null
  }

  Write-Host ">> stopping service $ServiceName" -ForegroundColor Cyan
  Run-Native "sc.exe" @("stop",$ServiceName) | Out-Null
  Start-Sleep -Seconds 2

  foreach ($d in $dumps) {
    $db = $d.BaseName
    Write-Host ">> restoring $db" -ForegroundColor Cyan
    Psql-Postgres "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$db' AND pid<>pg_backend_pid();"
    Psql-Postgres "DROP DATABASE IF EXISTS $db;"
    Psql-Postgres "CREATE DATABASE $db;"
    $r = Run-Native $pgRestore @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"--no-owner","--no-privileges",$d.FullName)
    if ($r.Code -ne 0) {
      # pg_restore exits non-zero even on benign notices (e.g. --no-owner role messages),
      # so a non-zero code alone is NOT proof of failure. Treat it as a real failure only
      # when it actually logged an error line - otherwise a half-restored DB was being
      # reported as "RESTORE COMPLETE". The safety backup above protects against this throw.
      if ($r.Out -match '(?im)pg_restore:\s*error:' -or $r.Out -match '(?im)^\s*error:') {
        Write-Host $r.Out -ForegroundColor Red
        throw "pg_restore FAILED for '$db' - database may be incomplete. Restore aborted; use the prerestore safety backup if needed."
      }
      Write-Host $r.Out -ForegroundColor Yellow   # warnings only - non-fatal
    }
    if (Test-Path $GrantsSql) {
      $g = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-v","dbname=$db","-v","ON_ERROR_STOP=1","-f",$GrantsSql)
      if ($g.Code -ne 0) { Write-Host $g.Out -ForegroundColor Red; throw "re-grant failed on $db" }
    }
  }
}
finally {
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host ">> starting service $ServiceName" -ForegroundColor Cyan
  Run-Native "sc.exe" @("start",$ServiceName) | Out-Null
}
Write-Host "RESTORE COMPLETE: $($dbNames -join ', ')" -ForegroundColor Green
