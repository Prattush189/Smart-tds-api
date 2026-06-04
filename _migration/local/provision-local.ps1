<#
  provision-local.ps1 — stand up a PRIVATE PostgreSQL for the STANDALONE LOCAL
  install and load the SmartTds schema + seed + an admin user + a local licence.
  This is the PostgreSQL replacement for the old "SmartTDS Database.aip"
  (SQL Server Express 2008R2 + T-SQL scripts). The Advanced Installer "Database"
  project calls this as a custom action.

  Reuses the existing converted schema:
    _migration\phase1\pg\02_master_schema.sql   (master DDL)
    _migration\phase1\pg\03_master_seed_data.sql (1407 reference rows)
    _migration\phase5\02_licensing.sql          (licences + sessions)
    _migration\phase5\01_least_privilege_role.sql (per-DB grants)
    _migration\phase1\pg\01_smarttds_year_template.sql (per-year DDL)

  PostgreSQL binaries: pass -PgZip <EDB binaries zip> OR -PgBin <existing ...\pgsql\bin>.
  Get the "binaries only" zip from:
    https://www.enterprisedb.com/download-postgresql-binaries  (postgresql-16.x-x-windows-x64-binaries.zip)

  EXAMPLES
    # first install: extract bundled PG, init a private cluster on :5433, load everything
    pwsh _migration\local\provision-local.ps1 -PgZip C:\dl\postgresql-16-binaries.zip `
         -ApiDir _migration\local\dist\api -AdminPwd 'admin'

    # re-run against an already-extracted PG (idempotent; preserves existing data)
    pwsh _migration\local\provision-local.ps1 -PgBin C:\ProgramData\SmartTds\pgsql\bin
#>
[CmdletBinding()]
param(
  [string]   $InstallRoot = (Join-Path $env:ProgramData "SmartTds"),
  [string]   $PgZip,                                   # EDB binaries zip (first install)
  [string]   $PgBin,                                   # or an existing pgsql\bin
  [int]      $Port        = 5433,
  [string]   $SuperPwd    = "postgres",                # local superuser pwd (local-only)
  [string]   $AppPwd,                                  # smarttds_app pwd (random if blank)
  [string[]] $Years       = @("25","26"),
  [string]   $AdminUser   = "admin",
  [string]   $AdminPwd    = "admin",
  [string]   $LicenceKey  = "DEMO123456",              # the firm's REAL Licence Key (ServiceUL); becomes the admin user's prodkey
  [string]   $ApiDir                                   # optional: patch its appsettings.Local.json
)

$ErrorActionPreference = "Stop"
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$mig      = Resolve-Path (Join-Path $here "..")
$pgSql    = Join-Path $mig "phase1\pg"
$ph5      = Join-Path $mig "phase5"
$dataDir  = Join-Path $InstallRoot "data"
$logFile  = Join-Path $InstallRoot "pg.log"

# PS 5.1 / .NET Framework safe random bytes (the static RandomNumberGenerator.GetBytes(int)
# only exists in .NET 6+; the installer runs under Windows PowerShell 5.1).
function New-RandomBase64([int]$count) {
  $b = New-Object byte[] $count
  ([System.Security.Cryptography.RandomNumberGenerator]::Create()).GetBytes($b)
  return [Convert]::ToBase64String($b)
}

if (-not $AppPwd) { $AppPwd = New-RandomBase64 18 }
$prodkey  = $LicenceKey.Trim().ToUpperInvariant()

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

function Say($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }

# ---- run a native exe, capture combined output, fail on non-zero (PS5.1-safe) ----
function Run-Native([string]$exe,[string[]]$a){
  $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  $out  = & $exe @a 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  return [pscustomobject]@{ Code=$code; Out=($out | Out-String) }
}

# ===================================================================== #
# 1) resolve PostgreSQL binaries
# ===================================================================== #
if (-not $PgBin) {
  if (-not $PgZip) { throw "Provide -PgZip <EDB binaries zip> (first install) or -PgBin <existing pgsql\bin>." }
  if (-not (Test-Path $PgZip)) { throw "PgZip not found: $PgZip" }
  $pgRoot = Join-Path $InstallRoot "pgsql"
  if (-not (Test-Path (Join-Path $pgRoot "bin\postgres.exe"))) {
    Say "Extracting PostgreSQL binaries -> $pgRoot"
    Expand-Archive -Path $PgZip -DestinationPath $InstallRoot -Force   # zip contains a top-level 'pgsql' folder
  }
  $PgBin = Join-Path $pgRoot "bin"
}
foreach ($tool in @("postgres.exe","initdb.exe","pg_ctl.exe","psql.exe")) {
  if (-not (Test-Path (Join-Path $PgBin $tool))) { throw "Missing $tool in $PgBin" }
}
$initdb = Join-Path $PgBin "initdb.exe"
$pgctl  = Join-Path $PgBin "pg_ctl.exe"
$psql   = Join-Path $PgBin "psql.exe"
Say "PostgreSQL bin: $PgBin"

# ===================================================================== #
# 2) initialise a private cluster (once)
# ===================================================================== #
if (-not (Test-Path (Join-Path $dataDir "PG_VERSION"))) {
  Say "Initialising private cluster -> $dataDir"
  $pwfile = Join-Path $env:TEMP "_sttds_pw.txt"
  Set-Content -Path $pwfile -Value $SuperPwd -NoNewline -Encoding ascii
  $r = Run-Native $initdb @("-D",$dataDir,"-U","postgres","-A","scram-sha-256","--pwfile=$pwfile","-E","UTF8")
  Remove-Item $pwfile -Force -ErrorAction SilentlyContinue
  if ($r.Code -ne 0) { Write-Host $r.Out -ForegroundColor Red; throw "initdb failed" }

  # bind private + on a non-default port so we never clash with another PG; IST clock
  $conf = Join-Path $dataDir "postgresql.conf"
  Add-Content -Path $conf -Value "`n# --- SmartTds local ---`nport = $Port`nlisten_addresses = '127.0.0.1'`ntimezone = 'Asia/Kolkata'`nlog_timezone = 'Asia/Kolkata'`n"
} else {
  Say "Cluster already initialised (reusing $dataDir)" "Yellow"
}

# ===================================================================== #
# 3) start the server
# ===================================================================== #
$status = Run-Native $pgctl @("-D",$dataDir,"status")
if ($status.Out -notmatch "server is running") {
  Say "Starting PostgreSQL on 127.0.0.1:$Port"
  # CRITICAL: wait on the pg_ctl PROCESS, not its output streams. pg_ctl spawns the
  # long-running postgres server which inherits any redirected handle (pipe OR
  # Start-Process redirect file) and keeps it open forever -> the parent hangs.
  # Using raw Process with NO redirection + WaitForExit waits only on pg_ctl's exit;
  # postgres (the grandchild) keeps running detached. pg_ctl logs to $logFile via -l.
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName        = $pgctl
  $psi.Arguments       = "-D `"$dataDir`" -l `"$logFile`" -w -t 60 -o `"-p $Port`" start"
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow  = $true
  $pg = [System.Diagnostics.Process]::Start($psi)
  if (-not $pg.WaitForExit(90000)) { try { $pg.Kill() } catch {}; throw "pg_ctl start timed out (90s)" }
  if ($pg.ExitCode -ne 0) {
    Write-Host (Get-Content $logFile -Tail 40 -ErrorAction SilentlyContinue) -ForegroundColor Red
    throw "pg_ctl start failed (exit $($pg.ExitCode)) - see $logFile"
  }
  Say "PostgreSQL started."
} else {
  Say "PostgreSQL already running" "Yellow"
}

# ---- psql helpers (superuser, local) ----
$env:PGPASSWORD = $SuperPwd
function Psql-Scalar($db,$sql){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U","postgres","-d",$db,"-tAc",$sql)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "query failed on $db" }
  return $r.Out.Trim()
}
function Psql-Cmd($db,$sql){
  $r = Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U","postgres","-d",$db,"-v","ON_ERROR_STOP=1","-c",$sql)
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "command failed on $db" }
}
function Psql-File($db,$file,[string[]]$vars){
  if (-not (Test-Path $file)) { throw "SQL file not found: $file" }
  $a = @("-h","127.0.0.1","-p","$Port","-U","postgres","-d",$db,"-v","ON_ERROR_STOP=1")
  foreach($v in $vars){ $a += @("-v",$v) }
  $a += @("-f",$file)
  $r = Run-Native $psql $a
  if ($r.Code -ne 0){ Write-Host $r.Out -ForegroundColor Red; throw "script failed: $file" }
}
function Db-Exists($name){ (Psql-Scalar "postgres" "SELECT 1 FROM pg_database WHERE datname='$name'") -eq "1" }

# ===================================================================== #
# 4) least-privilege app role (create with the REAL password)
# ===================================================================== #
Say "Ensuring role smarttds_app"
$roleExists = (Psql-Scalar "postgres" "SELECT 1 FROM pg_roles WHERE rolname='smarttds_app'") -eq "1"
$pwEsc = $AppPwd.Replace("'", "''")
if ($roleExists) {
  Psql-Cmd "postgres" "ALTER ROLE smarttds_app LOGIN PASSWORD '$pwEsc' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;"
} else {
  Psql-Cmd "postgres" "CREATE ROLE smarttds_app LOGIN PASSWORD '$pwEsc' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;"
}

# ===================================================================== #
# 5) master DB: schema + reference data + licensing + grants
# ===================================================================== #
if (-not (Db-Exists "masterdbtds")) {
  Say "Creating masterdbtds"
  Psql-Cmd "postgres" "CREATE DATABASE masterdbtds;"
  Psql-File "masterdbtds" (Join-Path $pgSql "02_master_schema.sql")
  Say "  loading reference data (1407 rows)"
  Psql-File "masterdbtds" (Join-Path $pgSql "03_master_seed_data.sql")
  Psql-File "masterdbtds" (Join-Path $ph5  "02_licensing.sql")
} else {
  Say "masterdbtds already exists (skipping schema load)" "Yellow"
}
# grants are idempotent — re-run every time (role already created above, so 01's CREATE ROLE no-ops)
Psql-File "masterdbtds" (Join-Path $ph5 "01_least_privilege_role.sql") @("dbname=masterdbtds")

# ===================================================================== #
# 6) per-assessment-year DBs
# ===================================================================== #
foreach ($y in $Years) {
  $db = "smarttds$y"
  if (-not (Db-Exists $db)) {
    Say "Creating $db"
    Psql-Cmd "postgres" "CREATE DATABASE $db;"
    Psql-File $db (Join-Path $pgSql "01_smarttds_year_template.sql")
  } else {
    Say "$db already exists (skipping)" "Yellow"
  }
  Psql-File $db (Join-Path $ph5 "01_least_privilege_role.sql") @("dbname=$db")
}

# ===================================================================== #
# 7) seed a bootstrap admin USER in the local DB — UNBOUND (blank prodkey).
#    LOCAL mode authenticates users against THIS DB (no seat cap); the LICENCE
#    is validated by the API against smartbizin ServiceUL.svc. The admin is
#    seeded WITHOUT a licence key so the installer is generic: the firm types
#    its real Licence Key on the login screen and the first successful login
#    BINDS it to this user (bind-on-first-login). No licences row needed.
# ===================================================================== #
Say "Seeding bootstrap admin user '$AdminUser' (UNBOUND - licence key entered at first login)"
$iter = 100000
$salt = New-Object byte[] 16
([System.Security.Cryptography.RandomNumberGenerator]::Create()).GetBytes($salt)
$kdf  = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($AdminPwd, $salt, $iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$dollar  = [char]36
$pwdHash = "pbkdf2" + $dollar + $iter + $dollar + [Convert]::ToBase64String($salt) + $dollar + [Convert]::ToBase64String($kdf.GetBytes(32))
$uEsc   = $AdminUser.Replace("'", "''")

$userSql = ("INSERT INTO users (prodkey, username, name, pwd, emailid, mobile, usertype, " +
  "assesseeaddflag, assesseeeditflag, assesseedeleteflag, viewpwdflag, backupflag, " +
  "restoreflag, efilingflag, rptviewflag, editfiledreturnflag, " +
  "createdby, createdon, modifiedby, modifiedon, isdeleted) " +
  "VALUES ('','{0}','{0}','{1}','{0}@local','0000000000','ADMIN', " +
  "true,true,true,true,true,true,true,true,true, 1, now(), 1, now(), false) " +
  "ON CONFLICT (prodkey, username) DO UPDATE SET pwd=EXCLUDED.pwd, isdeleted=false, modifiedon=now();" `
  ) -f $uEsc,$pwdHash
Psql-Cmd "masterdbtds" $userSql

# ===================================================================== #
# 8) optional: patch the published API's appsettings.Local.json
# ===================================================================== #
if ($ApiDir) {
  $cfg = Join-Path $ApiDir "appsettings.Local.json"
  if (Test-Path $cfg) {
    Say "Patching $cfg (Db.Password, Db.Port, Jwt.Key)"
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $j.Db.Password = $AppPwd
    $j.Db.Port     = $Port
    $j.Jwt.Key     = New-RandomBase64 48
    ($j | ConvertTo-Json -Depth 8) | Set-Content -Path $cfg -Encoding utf8
  } else { Say "  (no appsettings.Local.json at $ApiDir - skip)" "Yellow" }
}

Say "`nDONE." "Green"
Say ("  PostgreSQL : 127.0.0.1:{0}  (data {1})" -f $Port,$dataDir)
Say ("  Databases  : masterdbtds, " + (($Years | ForEach-Object { "smarttds$_" }) -join ", "))
Say  "  App role   : smarttds_app  (pwd stored in API appsettings.Local.json)"
Say ("  Login      : {0} / {1}   (enter your REAL Licence Key on the login screen - it binds on first login)" -f $AdminUser,$AdminPwd)
Say  "  Licence    : validated by the API against smartbizin ServiceUL.svc (machine-bound). Seats: UNLIMITED (Local mode)." "Yellow"
Say  "`nNext: start the API (set ASPNETCORE_ENVIRONMENT=Local, run SmartTdsApi.exe), then test  http://127.0.0.1:5080/health" "Yellow"
