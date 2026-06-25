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
  [string]   $SuperPwd    = "Pass@123",                # local superuser pwd (FIXED across all installs for support)
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

# FIXED app-role password across ALL installs (senior's decision: one known password for
# easier remote support; the local PG only listens on 127.0.0.1 and smarttds_app is
# least-privilege). A fixed value also removes the per-install random->config drift that
# caused "28P01 / master:null". Override with -AppPwd only if you really need a unique one.
if (-not $AppPwd) { $AppPwd = "Pass@123" }
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
# A data dir that EXISTS but has NO PG_VERSION is a half-initialised / corrupt cluster (a
# prior initdb was interrupted, or files were only partly written/copied). initdb refuses a
# non-empty target, so a re-install would fail here every time ("a program run as part of
# the setup did not finish") and killing services does nothing for it. Such a dir holds no
# real data — a valid cluster ALWAYS has PG_VERSION — so clear it and init fresh.
if ((Test-Path $dataDir) -and -not (Test-Path (Join-Path $dataDir "PG_VERSION"))) {
  Say "Data dir exists but is not a valid cluster (no PG_VERSION) - clearing for a fresh init" "Yellow"
  Remove-Item $dataDir -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not (Test-Path (Join-Path $dataDir "PG_VERSION"))) {
  Say "Initialising private cluster -> $dataDir"
  $pwfile = Join-Path $env:TEMP "_sttds_pw.txt"
  Set-Content -Path $pwfile -Value $SuperPwd -NoNewline -Encoding ascii
  $r = Run-Native $initdb @("-D",$dataDir,"-U","postgres","-A","scram-sha-256","--pwfile=$pwfile","-E","UTF8")
  Remove-Item $pwfile -Force -ErrorAction SilentlyContinue
  if ($r.Code -ne 0) {
    Write-Host $r.Out -ForegroundColor Red
    # Surface the exit code + output IN the throw so the install transcript names the cause
    # (the previous bare "initdb failed" hid it). Empty output + a huge/negative exit code
    # (e.g. -1073741515 / 0xC0000135 STATUS_DLL_NOT_FOUND) means initdb.exe could not even
    # launch — almost always the Microsoft Visual C++ Redistributable (x64) is missing on
    # the target machine (the EDB "binaries-only" PostgreSQL zip depends on it).
    $hint = ""
    if (("$($r.Out)").Trim().Length -eq 0) {
      $hint = "  (no initdb output: initdb.exe likely failed to launch - install the Microsoft Visual C++ Redistributable x64 on this machine)"
    }
    throw ("initdb failed (exit " + $r.Code + "): " + ("$($r.Out)").Trim() + $hint)
  }

  # bind private + on a non-default port so we never clash with another PG; IST clock
  $conf = Join-Path $dataDir "postgresql.conf"
  Add-Content -Path $conf -Value "`n# --- SmartTds local ---`nport = $Port`nlisten_addresses = '127.0.0.1'`ntimezone = 'Asia/Kolkata'`nlog_timezone = 'Asia/Kolkata'`n"
} else {
  Say "Cluster already initialised (reusing $dataDir)" "Yellow"
}

# ===================================================================== #
# 3) start the server
# ===================================================================== #
# A postgres that was KILLED (not cleanly stopped) — e.g. by the installer's clean-slate or
# a crash — leaves a stale postmaster.pid lock. If nothing is actually listening on our
# port, that lock is stale: remove it so pg_ctl start does not refuse with "lock file
# postmaster.pid already exists / is another postmaster (PID ...) running" (which fails the
# MSI). A genuinely running server (status below reports it) is left untouched.
$pidFile = Join-Path $dataDir "postmaster.pid"
if (Test-Path $pidFile) {
  $listening = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
  if ($listening.Count -eq 0) {
    Say "Removing stale postmaster.pid (nothing listening on $Port)" "Yellow"
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  }
}
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

# ---- ensure the postgres superuser password is the FIXED value (heals upgrades) ----
# A FRESH cluster already has $SuperPwd (initdb --pwfile above). An EXISTING cluster from an
# older install may still carry a different superuser password (e.g. the legacy "postgres"),
# so connecting with $SuperPwd would fail. Find the password that works from a small
# candidate list, then ALTER the superuser to $SuperPwd — every install converges to one
# known value (backup/restore/migrate all rely on it).
$env:PGPASSWORD = $SuperPwd
$superOk = ((Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U","postgres","-d","postgres","-tAc","select 1")).Code -eq 0)
if (-not $superOk) {
  foreach ($cand in @('postgres','pw')) {
    $env:PGPASSWORD = $cand
    if ((Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U","postgres","-d","postgres","-tAc","select 1")).Code -eq 0) {
      Say "Updating superuser password to the fixed value" "Yellow"
      Run-Native $psql @("-h","127.0.0.1","-p","$Port","-U","postgres","-d","postgres","-c",("alter user postgres password '" + $SuperPwd.Replace("'","''") + "'")) | Out-Null
      $env:PGPASSWORD = $SuperPwd
      $superOk = $true
      break
    }
  }
}
if (-not $superOk) { throw "Could not authenticate as the postgres superuser with any known password (tried the configured one, 'postgres', 'pw')." }

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
# RLS tenant isolation (idempotent) — defense-in-depth behind the API
$rlsMaster = Join-Path $ph5 "03_rls_master.sql"
if (Test-Path $rlsMaster) { Psql-File "masterdbtds" $rlsMaster }
else { Say "  (03_rls_master.sql not bundled - master RLS NOT applied; add it to the installer)" "Yellow" }

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
  # RLS tenant isolation for the year DB (idempotent)
  $rlsYear = Join-Path $ph5 "04_rls_year.sql"
  if (Test-Path $rlsYear) { Psql-File $db $rlsYear }
  else { Say "  (04_rls_year.sql not bundled - year RLS NOT applied; add it to the installer)" "Yellow" }
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

# Seed the bootstrap admin ONLY if no such user exists yet (any prodkey). This is
# idempotent across re-provisions even after bind-on-first-login changed the admin's
# prodkey (ON CONFLICT on prodkey+username would otherwise insert a duplicate).
$userSql = ("INSERT INTO users (prodkey, username, name, pwd, emailid, mobile, usertype, " +
  "assesseeaddflag, assesseeeditflag, assesseedeleteflag, viewpwdflag, backupflag, " +
  "restoreflag, efilingflag, rptviewflag, editfiledreturnflag, " +
  "createdby, createdon, modifiedby, modifiedon, isdeleted) " +
  "SELECT '','{0}','{0}','{1}','{0}@local','0000000000','ADMIN', " +
  "true,true,true,true,true,true,true,true,true, 1, now(), 1, now(), false " +
  "WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='{0}');" `
  ) -f $uEsc,$pwdHash
Psql-Cmd "masterdbtds" $userSql

# ===================================================================== #
# 8) optional: patch the published API's appsettings.Local.json
# ===================================================================== #
if ($ApiDir) {
  $cfg = Join-Path $ApiDir "appsettings.Local.json"
  if (Test-Path $cfg) {
    Say "Patching $cfg (Db.Password, Db.Port, Jwt.Key, Backup.PgBin)"
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $j.Db.Password = $AppPwd
    $j.Db.Port     = $Port
    $j.Jwt.Key     = New-RandomBase64 48
    # tell the API where pgsql lives (backup/restore/migrate). It's under the app dir,
    # NOT ProgramData, so the script defaults would be wrong without this.
    if (-not ($j.PSObject.Properties.Name -contains 'Backup')) {
      $j | Add-Member -NotePropertyName Backup -NotePropertyValue ([pscustomobject]@{})
    }
    $j.Backup | Add-Member -NotePropertyName PgBin -NotePropertyValue $PgBin -Force
    # Backups live next to the app (same drive), NOT C:\ProgramData. Tell the API where to
    # write/list them so its Backup screen matches what the scripts produce. (The API's
    # RunScript forwards this as -BackupRoot to backup-local.ps1.)
    $j.Backup | Add-Member -NotePropertyName BackupRoot -NotePropertyValue (Join-Path $InstallRoot "backups") -Force
    ($j | ConvertTo-Json -Depth 8) | Set-Content -Path $cfg -Encoding utf8

    # Set the role to the FIXED local constant ($AppPwd = Pass@123). The API hardcodes the
    # same constant in Local mode (DbOptions.LocalPassword), so role + API always match.
    # Deliberately NOT read back from appsettings: a preserved/stale file must never be able
    # to set a wrong role password (that was the recurring "28P01" drift). The constant is
    # the single source of truth on both sides.
    Psql-Cmd "postgres" ("ALTER ROLE smarttds_app PASSWORD '" + $AppPwd.Replace("'","''") + "';")
    Say "  Role password set to the fixed local value."
  } else {
    # appsettings.Local.json is MISSING (not packaged by the installer, or removed). Without
    # it the API falls back to the placeholder appsettings.json (port 55432 / password "pw")
    # and can NEVER reach the local DB -> /health master:null -> login "unexpected error".
    # So CREATE it from scratch with THIS machine's real values, and sync the role to match.
    Say "appsettings.Local.json missing at $ApiDir - creating it" "Yellow"
    $newCfg = [pscustomobject]@{
      "//"         = "LOCAL profile (auto-created by provision-local because it was missing). Activated by ASPNETCORE_ENVIRONMENT=Local."
      AllowedHosts = "*"
      Urls         = "http://127.0.0.1:5080"
      Logging      = [pscustomobject]@{ LogLevel = [pscustomobject]@{ Default = "Information"; "Microsoft.AspNetCore" = "Warning" } }
      Db           = [pscustomobject]@{
        Host = "127.0.0.1"; Port = $Port; Username = "smarttds_app"; Password = $AppPwd
        MasterDatabase = "masterdbtds"; YearDatabaseTemplate = "smarttds{0}"
      }
      Jwt          = [pscustomobject]@{ Issuer = "SmartTdsApi"; Audience = "SmartTdsClient"; Key = (New-RandomBase64 48); ExpiryMinutes = 480 }
      Licensing    = [pscustomobject]@{
        Mode = "Local"
        ServiceUrls = @("http://www.smartbizin.com/checking/ServiceUL.svc", "http://www.smartbizindia.com/checking/ServiceUL.svc")
        Auth = "Hello.123"; ProductName = "stdsN"; LicenceType = "Paid"; RecheckHours = 24
      }
      Backup       = [pscustomobject]@{ PgBin = $PgBin; BackupRoot = (Join-Path $InstallRoot "backups") }
    }
    ($newCfg | ConvertTo-Json -Depth 8) | Set-Content -Path $cfg -Encoding utf8
    # The role must match the password we just wrote so the API can connect.
    Psql-Cmd "postgres" ("ALTER ROLE smarttds_app PASSWORD '" + $AppPwd.Replace("'", "''") + "';")
    Say "  Created appsettings.Local.json and synced the role password."
  }
}

Say "`nDONE." "Green"
Say ("  PostgreSQL : 127.0.0.1:{0}  (data {1})" -f $Port,$dataDir)
Say ("  Databases  : masterdbtds, " + (($Years | ForEach-Object { "smarttds$_" }) -join ", "))
Say  "  App role   : smarttds_app  (pwd stored in API appsettings.Local.json)"
Say ("  Login      : {0} / (the admin password set during install)   (enter your REAL Licence Key on the login screen - it binds on first login)" -f $AdminUser)
Say  "  Licence    : validated by the API against smartbizin ServiceUL.svc (machine-bound). Seats: UNLIMITED (Local mode)." "Yellow"
Say  "`nNext: start the API (set ASPNETCORE_ENVIRONMENT=Local, run SmartTdsApi.exe), then test  http://127.0.0.1:5080/health" "Yellow"
