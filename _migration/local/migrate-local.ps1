<#
  migrate-local.ps1 — apply forward-only schema migrations to the LOCAL PostgreSQL.
  Replaces the old SQL-Server FrmUpdateDb (version-gated T-SQL on login), which
  doesn't work against PostgreSQL.

  WHY: provision-local.ps1 lays down the BASELINE schema and SKIPS databases that
  already exist. So when a new app version needs a schema change, EXISTING installs
  never get it. This runner closes that gap: each new app version ships delta .sql
  files; this applies the ones a database hasn't seen yet, tracked per-DB in a
  `schema_migrations` table. Safe to run every install/update — it's idempotent.

  MIGRATION FILES live in _migration\local\migrations\ and are named:
      <target>__<NNNN>__<description>.sql
    target = master  -> applied to masterdbtds
    target = year    -> applied to EVERY smarttds<YY> database
  Examples:
      master__0001__add_assessee_note.sql
      year__0001__add_tdsentry_flag.sql
  Apply order = filename sort. Write each migration IDEMPOTENTLY
  (ADD COLUMN IF NOT EXISTS, CREATE TABLE IF NOT EXISTS, ...) as a belt-and-braces
  measure; the runner already wraps file + bookkeeping in ONE transaction.

  NOTE: year migrations are forward-only deltas; the year TEMPLATE
  (01_smarttds_year_template.sql) stays at baseline. A brand-new year DB is created
  from the template, then this runner brings it up to date — so new and existing
  year DBs converge to the same schema.

  Usage:
    powershell -ExecutionPolicy Bypass -File migrate-local.ps1
    powershell -ExecutionPolicy Bypass -File migrate-local.ps1 -Port 5433 -SuperPwd postgres
#>
[CmdletBinding()]
param(
  [string] $InstallRoot = (Join-Path $env:ProgramData "SmartTds"),
  [string] $PgBin,                                  # default <InstallRoot>\pgsql\bin
  [int]    $Port      = 5433,
  [string] $SuperUser = "postgres",
  [string] $SuperPwd  = "postgres",
  [string] $MigrationsDir,                          # default <script dir>\migrations
  [string] $GrantsSql                               # default ..\phase5\01_least_privilege_role.sql
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $PgBin)         { $PgBin         = Join-Path $InstallRoot "pgsql\bin" }
if (-not $MigrationsDir) { $MigrationsDir = Join-Path $here "migrations" }
if (-not $GrantsSql)     { $GrantsSql     = Join-Path $here "..\phase5\01_least_privilege_role.sql" }
$psql = Join-Path $PgBin "psql.exe"
if (-not (Test-Path $psql)) { throw "psql.exe not found in $PgBin" }
$env:PGPASSWORD = $SuperPwd
function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

function Run-Native([string]$exe,[string[]]$a){
  $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  $out  = & $exe @a 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  return [pscustomobject]@{ Code=$code; Out=($out | Out-String) }
}
function Scalar($db,$sql){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-tAc",$sql)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "query failed on $db" }
  return $r.Out.Trim()
}
function Exec($db,$sql){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-v","ON_ERROR_STOP=1","-c",$sql)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "command failed on $db" }
}
function ExecFile($db,$file){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-v","ON_ERROR_STOP=1","-f",$file)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "migration failed on ${db}: $file" }
}

if (-not (Test-Path $MigrationsDir)) { Say "No migrations dir ($MigrationsDir) - nothing to do." "Yellow"; return }
$files = Get-ChildItem $MigrationsDir -Filter *.sql -ErrorAction SilentlyContinue | Sort-Object Name
if (-not $files) { Say "No migration files - nothing to do." "Yellow"; return }

# discover target databases
$dbList = (Scalar "postgres" "select datname from pg_database where datname='masterdbtds' or datname like 'smarttds%' order by datname") `
          -split "`r?`n" | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() }
$yearDbs = $dbList | Where-Object { $_ -like "smarttds*" }

# ensure the bookkeeping table exists in every DB
foreach ($db in $dbList) {
  Exec $db "CREATE TABLE IF NOT EXISTS schema_migrations (filename text PRIMARY KEY, applied_on timestamptz NOT NULL DEFAULT now());"
}

$applied = 0
foreach ($f in $files) {
  $name = $f.Name
  if ($name -notmatch '^(master|year)__') { Say "  skip (bad name, need master__/year__): $name" "Yellow"; continue }
  $target  = $matches[1]
  $targets = if ($target -eq "master") { @("masterdbtds") } else { $yearDbs }

  foreach ($db in $targets) {
    $done = (Scalar $db "select 1 from schema_migrations where filename='$($name.Replace("'","''"))'") -eq "1"
    if ($done) { continue }
    Say "  applying $name -> $db"
    # atomic: file body + bookkeeping insert in ONE transaction (temp combined file)
    $body = Get-Content $f.FullName -Raw
    $combined = "BEGIN;`n" + $body + "`nINSERT INTO schema_migrations(filename) VALUES('" + $name.Replace("'","''") + "');`nCOMMIT;`n"
    $tmp = Join-Path $env:TEMP ("mig_" + [System.IO.Path]::GetRandomFileName() + ".sql")
    Set-Content -Path $tmp -Value $combined -Encoding UTF8
    try { ExecFile $db $tmp } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    $applied++
  }
}

# re-apply least-privilege grants (new tables/columns need grants for smarttds_app)
if ($applied -gt 0 -and (Test-Path $GrantsSql)) {
  foreach ($db in $dbList) {
    $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U",$SuperUser,"-d",$db,"-v","dbname=$db","-v","ON_ERROR_STOP=1","-f",$GrantsSql)
    if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "re-grant failed on $db" }
  }
}

Say ("DONE. Applied {0} migration step(s) across: {1}" -f $applied, ($dbList -join ", ")) "Green"
