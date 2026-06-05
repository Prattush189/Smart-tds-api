# Repeatable PostgreSQL migration runner for SmartTds (Phase 1).
# Builds the shared master DB (schema + REQUIRED reference data) and one
# per-assessment-year DB per year requested.
# Usage:
#   .\run_pg_migration.ps1                            # years 25 and 26 in container 'sttest'
#   .\run_pg_migration.ps1 -Years 25,26,27
#   .\run_pg_migration.ps1 -Container sttest -Years 26
param(
    [string]$Container = "sttest",
    [string[]]$Years = @("25","26")
)
$ErrorActionPreference = "Stop"
$pg = Join-Path $PSScriptRoot "pg"

function Psql([string]$db, [string]$file) {
    docker cp $file "${Container}:/tmp/run.sql" | Out-Null
    $o = docker exec $Container psql -U postgres -d $db -v ON_ERROR_STOP=1 -f /tmp/run.sql 2>&1
    $err = $o | Select-String ERROR
    if ($err) { Write-Host "  ERROR in $file :" -ForegroundColor Red; $err; throw "failed: $file" }
}

Write-Host "== (re)creating master DB ==" -ForegroundColor Cyan
docker exec $Container psql -U postgres -c "DROP DATABASE IF EXISTS masterdbtds;" | Out-Null
docker exec $Container psql -U postgres -c "CREATE DATABASE masterdbtds;"          | Out-Null
Write-Host "== master schema ==" -ForegroundColor Cyan
Psql masterdbtds (Join-Path $pg "02_master_schema.sql")
Write-Host "== master reference data (1407 rows) ==" -ForegroundColor Cyan
Psql masterdbtds (Join-Path $pg "03_master_seed_data.sql")
Write-Host "== licensing + sessions tables ==" -ForegroundColor Cyan
Psql masterdbtds (Join-Path $PSScriptRoot "..\phase5\02_licensing.sql")
Write-Host "== RLS tenant isolation (defense-in-depth) ==" -ForegroundColor Cyan
Psql masterdbtds (Join-Path $PSScriptRoot "..\phase5\03_rls_master.sql")

foreach ($y in $Years) {
    $yearDb = "smarttds$y"
    Write-Host "== (re)creating $yearDb ==" -ForegroundColor Cyan
    docker exec $Container psql -U postgres -c "DROP DATABASE IF EXISTS $yearDb;"   | Out-Null
    docker exec $Container psql -U postgres -c "CREATE DATABASE $yearDb;"           | Out-Null
    Psql $yearDb (Join-Path $pg "01_smarttds_year_template.sql")
}

$mt = docker exec $Container psql -U postgres -d masterdbtds -t -c "select count(*) from information_schema.tables where table_schema='public';"
$sr = docker exec $Container psql -U postgres -d masterdbtds -t -c "select count(*) from (select 1 from district union all select 1 from country union all select 1 from tdsrate union all select 1 from tdsnature union all select 1 from tdsentriessection union all select 1 from state union all select 1 from tdsded80 union all select 1 from check_period union all select 1 from applicationparams union all select 1 from aymaster) z;"
Write-Host "`nDONE." -ForegroundColor Green
Write-Host ("  masterdbtds tables : " + $mt.Trim() + " (expect 28)")
Write-Host ("  reference rows     : " + $sr.Trim() + " (expect 1407)")
foreach ($y in $Years) {
    $yt = docker exec $Container psql -U postgres -d "smarttds$y" -t -c "select count(*) from information_schema.tables where table_schema='public';"
    Write-Host ("  smarttds$y tables   : " + $yt.Trim() + " (expect 14)")
}
Write-Host "`nNext: create a login user with  _migration\tools\create_user.ps1" -ForegroundColor Yellow
