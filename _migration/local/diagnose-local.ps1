<#
  diagnose-local.ps1 - ONE read-only health check you can run on any client PC to
  find out WHY a SmartTds local install isn't working (or to confirm it's healthy).

  It changes NOTHING. It only reads: files, services, ports, the database, the API,
  Windows Defender quarantine/exclusions, the MSI event log and the install log.
  At the end it prints a PASS / WARN / FAIL summary and writes a full report to the
  Desktop (SmartTds-Diagnostics-<PC>-<time>.txt) that the tester can send back.

  HOW TO RUN (tester, no install needed):
    1. Right-click Start -> "Windows PowerShell (Admin)"   (admin = best; it still
       works without admin, but a few checks will say "need admin").
    2. Run:
         powershell -ExecutionPolicy Bypass -File "<path>\diagnose-local.ps1"
       If the app is installed, it auto-finds the folder. To point it explicitly:
         ... -File "<path>\diagnose-local.ps1" -AppDir "D:\SmartTDS"

  Send back the .txt file it drops on the Desktop.
#>
[CmdletBinding()]
param(
  [string] $AppDir,                 # install folder (auto-detected if omitted)
  [int]    $ApiPort = 5080,
  [int]    $PgPort  = 5433,
  [string] $SuperUser = "postgres",
  [string] $SuperPwd  = "Pass@123", # local PG superuser pw (FIXED across installs; set by provision-local.ps1)
  [string] $OutFile               # where to write the report (default: a timestamped file on the Desktop)
)

# never abort the whole report on one failing probe
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$report = if ($OutFile) { $OutFile } else { Join-Path ([Environment]::GetFolderPath('Desktop')) ("SmartTds-Diagnostics-{0}-{1}.txt" -f $env:COMPUTERNAME,$stamp) }
try { Start-Transcript -Path $report -Force | Out-Null } catch { }

$script:Pass = 0; $script:Warn = 0; $script:Fail = 0
function Section($t){ Write-Host "`n==== $t ====" -ForegroundColor White }
function OK($m){   $script:Pass++; Write-Host "  [ OK ] $m"   -ForegroundColor Green }
function WARN($m){ $script:Warn++; Write-Host "  [WARN] $m"   -ForegroundColor Yellow }
function FAIL($m){ $script:Fail++; Write-Host "  [FAIL] $m"   -ForegroundColor Red }
function INFO($m){ Write-Host "  - $m" -ForegroundColor Gray }

Write-Host "SmartTds local-install diagnostics" -ForegroundColor Cyan
Write-Host ("Run: {0}   PC: {1}   User: {2}" -f (Get-Date), $env:COMPUTERNAME, $env:USERNAME)

# --- elevation ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($IsAdmin) { OK "Running elevated (Administrator)." }
else { WARN "NOT elevated - service/Defender/event-log checks may be limited. Re-run as Administrator for the full picture." }

# ---------------------------------------------------------------------------
Section "1. System"
try {
  $os = Get-CimInstance Win32_OperatingSystem
  INFO ("OS: {0} (build {1})" -f $os.Caption, $os.BuildNumber)
} catch { }
INFO ("PowerShell: {0}" -f $PSVersionTable.PSVersion)

# pending reboot can wedge MSI installs/uninstalls
$reboot = $false
foreach ($k in @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) {
  if (Test-Path $k) { $reboot = $true }
}
$pfro = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue)
if ($pfro) { $reboot = $true }
if ($reboot) { WARN "A Windows REBOOT is pending - this can make MSI install/uninstall fail. Reboot before installing." }
else { OK "No pending reboot." }

# ---------------------------------------------------------------------------
Section "2. Locate the install"
if (-not $AppDir) {
  # a) MSI uninstall registry (DisplayName like SmartTDS)
  foreach ($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                      'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
      Where-Object { $_.DisplayName -like '*SmartTDS*' -or $_.DisplayName -like '*Smart Tds*' } |
      ForEach-Object {
        INFO ("Registered product: {0} {1}  (InstallLocation: {2})" -f $_.DisplayName,$_.DisplayVersion,$_.InstallLocation)
        if (-not $AppDir -and $_.InstallLocation -and (Test-Path (Join-Path $_.InstallLocation 'api\SmartTdsApi.exe'))) {
          $AppDir = $_.InstallLocation.TrimEnd('\')
        }
      }
  }
  # b) common locations
  if (-not $AppDir) {
    $cands = @()
    foreach ($d in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
      $cands += (Join-Path $d 'SmartTDS'); $cands += (Join-Path $d 'SmartTds')
    }
    $cands += (Join-Path ${env:ProgramFiles} 'SmartTDS')
    if (${env:ProgramFiles(x86)}) { $cands += (Join-Path ${env:ProgramFiles(x86)} 'SmartTDS') }
    foreach ($c in $cands) {
      if ($c -and (Test-Path (Join-Path $c 'api\SmartTdsApi.exe'))) { $AppDir = $c; break }
    }
  }
}
if ($AppDir -and (Test-Path $AppDir)) { OK ("Install folder: {0}" -f $AppDir) }
else { FAIL "Could not find the install folder. Pass it with -AppDir `"D:\SmartTDS`" and re-run." }

# data root: <AppDir>\Data (current builds) or C:\ProgramData\SmartTds (older)
$DataRoot = $null
if ($AppDir -and (Test-Path (Join-Path $AppDir 'Data'))) { $DataRoot = Join-Path $AppDir 'Data' }
elseif (Test-Path (Join-Path $env:ProgramData 'SmartTds')) { $DataRoot = Join-Path $env:ProgramData 'SmartTds' }
if ($DataRoot) { INFO ("Data root: {0}" -f $DataRoot) }

# OneDrive trap - placeholders look present but aren't really on disk
if ($AppDir -and ($AppDir -match 'OneDrive' -or $AppDir -match '\\Users\\[^\\]+\\(Documents|Desktop)')) {
  WARN "Install path looks like it's under OneDrive / a synced user folder - files can be cloud placeholders that fail to open. Install to a plain path like D:\SmartTDS."
}

# disk space on the install drive
if ($AppDir) {
  $drv = (Split-Path -Qualifier $AppDir)
  try {
    $free = (Get-PSDrive ($drv.TrimEnd(':')) -ErrorAction Stop).Free
    if ($free -lt 1GB) { WARN ("Only {0:N1} GB free on {1} - PostgreSQL + backups need headroom." -f ($free/1GB),$drv) }
    else { OK ("Free space on {0}: {1:N1} GB" -f $drv, ($free/1GB)) }
  } catch { }
}

# ---------------------------------------------------------------------------
Section "3. Required files present (this is the 'files disappeared' check)"
if ($AppDir) {
  $need = @(
    'api\SmartTdsApi.exe',
    'api\appsettings.Local.json',
    'pgsql\bin\postgres.exe',
    'pgsql\bin\psql.exe',
    'pgsql\bin\pg_ctl.exe',
    'pgsql\bin\initdb.exe',
    '_migration\local\install-local.ps1',
    '_migration\local\provision-local.ps1'
  )
  foreach ($rel in $need) {
    $p = Join-Path $AppDir $rel
    if (Test-Path $p) { OK $rel } else { FAIL ("MISSING: {0}   <- if it showed earlier then vanished, suspect antivirus quarantine or an MSI rollback" -f $rel) }
  }
}

# ---------------------------------------------------------------------------
Section "4. Visual C++ runtime (PostgreSQL needs it; missing = initdb/postgres fail)"
$vc = Test-Path (Join-Path $env:SystemRoot 'System32\vcruntime140.dll')
$vc14 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction SilentlyContinue
if ($vc -or $vc14) { OK "VC++ runtime present (vcruntime140)." }
else { FAIL "VC++ x64 runtime NOT found - PostgreSQL can't run. Install Microsoft VC++ 2015-2022 x64 redistributable." }

# ---------------------------------------------------------------------------
Section "5. Windows services"
foreach ($svc in 'SmartTdsPg','SmartTdsApi') {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if (-not $s) { FAIL ("Service {0} not installed." -f $svc); continue }
  $startType = (Get-CimInstance Win32_Service -Filter "Name='$svc'" -ErrorAction SilentlyContinue).StartMode
  if ($s.Status -eq 'Running') { OK ("{0} = Running (start: {1})" -f $svc,$startType) }
  else { FAIL ("{0} = {1} (start: {2}) - should be Running." -f $svc,$s.Status,$startType) }
}

# ---------------------------------------------------------------------------
Section "6. Network ports"
function Probe-Port($port,$label){
  $own = $null
  try { $own = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
  if ($own) {
    $pname = (Get-Process -Id $own.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    OK ("{0} port {1} is LISTENING (pid {2} / {3})" -f $label,$port,$own.OwningProcess,$pname)
  } else { FAIL ("{0} port {1} is NOT listening - its service isn't serving." -f $label,$port) }
}
Probe-Port $PgPort  "PostgreSQL"
Probe-Port $ApiPort "API"

# ---------------------------------------------------------------------------
Section "7. PostgreSQL connectivity + data"
$psql = $null
if ($AppDir) { $psql = Join-Path $AppDir 'pgsql\bin\psql.exe' }
if ($psql -and (Test-Path $psql)) {
  $env:PGPASSWORD = $SuperPwd
  $ver = & $psql -h 127.0.0.1 -p $PgPort -U $SuperUser -d postgres -tAc "select version()" 2>&1
  if ($LASTEXITCODE -eq 0 -and "$ver" -match 'PostgreSQL') {
    OK ("Connected. {0}" -f ("$ver".Trim()))
    $dbs = & $psql -h 127.0.0.1 -p $PgPort -U $SuperUser -d postgres -tAc "select datname from pg_database where datname like 'smarttds%' or datname='masterdbtds' order by 1" 2>&1
    INFO ("Databases: {0}" -f (($dbs -join ', ').Trim()))
    foreach ($must in 'masterdbtds') {
      if ($dbs -match $must) { OK ("DB present: {0}" -f $must) } else { FAIL ("DB MISSING: {0} - provisioning didn't finish." -f $must) }
    }
    $cnt = & $psql -h 127.0.0.1 -p $PgPort -U $SuperUser -d masterdbtds -tAc "select count(*) from assessee" 2>&1
    if ($LASTEXITCODE -eq 0) { INFO ("Assessees in masterdbtds: {0}" -f ("$cnt".Trim())) }
  } else {
    FAIL ("Could not connect to PostgreSQL on 127.0.0.1:{0} as {1}. Output: {2}" -f $PgPort,$SuperUser,("$ver".Trim()))
  }
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
} else { WARN "psql.exe not found - skipped DB check (install folder not located)." }

# ---------------------------------------------------------------------------
Section "8. API /health"
try {
  $h = Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/health" -f $ApiPort) -TimeoutSec 10
  if ($h.master) { OK ("API healthy: status={0}, master={1}, name={2}" -f $h.status,$h.master,$h.name) }
  else { FAIL ("API answered but master=NULL - API is up but can't reach the DB (password drift / PG down / DB missing). Check api log below.") }
} catch {
  FAIL ("API not answering on http://127.0.0.1:{0}/health : {1}" -f $ApiPort, $_.Exception.Message)
}

# ---------------------------------------------------------------------------
Section "9. API config (appsettings.Local.json)"
if ($AppDir) {
  $cfg = Join-Path $AppDir 'api\appsettings.Local.json'
  if (Test-Path $cfg) {
    try {
      $j = Get-Content $cfg -Raw | ConvertFrom-Json
      if ($j.Db.Password) { OK ("Db.Password is set (len {0})." -f $j.Db.Password.Length) } else { FAIL "Db.Password is EMPTY in appsettings.Local.json." }
      if ($j.Db.Port)     { INFO ("Db.Port = {0}" -f $j.Db.Port) }
      if ($j.Jwt.Key)     { OK ("Jwt.Key is set (len {0})." -f $j.Jwt.Key.Length) } else { WARN "Jwt.Key empty - API may fail to start (fail-fast guard)." }
      if ($j.Licensing.Mode) { INFO ("Licensing:Mode = {0}" -f $j.Licensing.Mode) }
    } catch { WARN ("Could not parse appsettings.Local.json: {0}" -f $_.Exception.Message) }
  } else { FAIL "appsettings.Local.json missing - provisioning didn't write the API config (this is the classic 'master:null' cause)." }
}

# ---------------------------------------------------------------------------
Section "10. Antivirus / Windows Defender (the #1 'files vanish / works on one PC not another' cause)"
try {
  $mp = Get-MpComputerStatus -ErrorAction Stop
  INFO ("Defender real-time protection: {0}" -f $mp.RealTimeProtectionEnabled)
  $pref = Get-MpPreference -ErrorAction Stop
  $excl = @($pref.ExclusionPath)
  $covered = $false
  if ($AppDir) { foreach ($e in $excl) { if ($e -and $AppDir -like "$e*") { $covered = $true } } }
  if ($covered) { OK ("Install folder is in Defender's exclusion list.") }
  else { WARN ("Install folder is NOT excluded in Defender. If files get quarantined, add an exclusion for $AppDir.") }
  if ($excl.Count) { INFO ("Current exclusions: {0}" -f ($excl -join '; ')) }

  # recent threats touching our files
  $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 40
  $hit = $threats | Where-Object { ($_.Resources -join ' ') -match 'SmartTds|postgres|pgsql|install-local|SmartTdsApi' }
  if ($hit) {
    FAIL "Defender has flagged/quarantined SmartTds-related files - THIS is why files disappear. Details:"
    $hit | ForEach-Object { INFO (" detected {0}  ->  {1}" -f $_.InitialDetectionTime, ($_.Resources -join ', ')) }
  } else {
    OK "No SmartTds-related Defender detections found in recent history."
  }
} catch {
  WARN ("Could not query Defender (need admin, or a 3rd-party AV is in charge): {0}. If a 3rd-party AV is installed, check ITS quarantine log manually." -f $_.Exception.Message)
}
# any 3rd-party AV present?
try {
  $av = Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction Stop
  if ($av) { INFO ("Registered AV product(s): {0}" -f (($av | Select-Object -ExpandProperty displayName) -join ', ')) }
} catch { }

# ---------------------------------------------------------------------------
Section "11. MSI install/uninstall history (rollbacks = the 'files there then gone' symptom)"
try {
  $msi = Get-WinEvent -FilterHashtable @{ LogName='Application'; ProviderName='MsiInstaller'; StartTime=(Get-Date).AddDays(-14) } -MaxEvents 40 -ErrorAction Stop |
         Where-Object { $_.Message -match 'SmartTDS|Smart Tds|rollback|removal|Reconfigured|Installation completed|did not finish' }
  if ($msi) {
    INFO "Recent MSI events (last 14 days):"
    $msi | Select-Object -First 12 | ForEach-Object { INFO (" {0}  {1}" -f $_.TimeCreated, ($_.Message -replace '\s+',' ').Substring(0,[Math]::Min(160,($_.Message -replace '\s+',' ').Length))) }
  } else { OK "No notable SmartTds MSI events in the last 14 days." }
} catch { WARN ("Could not read the Application event log (need admin): {0}" -f $_.Exception.Message) }

# ---------------------------------------------------------------------------
Section "12. Last install log"
$logCandidates = @()
if ($DataRoot) { $logCandidates += (Join-Path $DataRoot 'logs\install-local.log') }
$logCandidates += (Join-Path $env:ProgramData 'SmartTds\logs\install-local.log')
$log = $logCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($log) {
  INFO ("Tail of {0}:" -f $log)
  Get-Content $log -Tail 25 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
} else { WARN "No install-local.log found (install may never have run its custom action)." }

# ---------------------------------------------------------------------------
Write-Host "`n==================== SUMMARY ====================" -ForegroundColor White
Write-Host ("  PASS: {0}   WARN: {1}   FAIL: {2}" -f $script:Pass,$script:Warn,$script:Fail) -ForegroundColor White
if ($script:Fail -eq 0 -and $script:Warn -eq 0) { Write-Host "  Looks healthy." -ForegroundColor Green }
elseif ($script:Fail -eq 0) { Write-Host "  Working, with warnings to review above." -ForegroundColor Yellow }
else { Write-Host "  Problems found - see the [FAIL] lines above. Most common: antivirus quarantine, missing VC++ runtime, or a service not running." -ForegroundColor Red }
Write-Host ("`n  Full report saved to: {0}" -f $report) -ForegroundColor Cyan

try { Stop-Transcript | Out-Null } catch { }
