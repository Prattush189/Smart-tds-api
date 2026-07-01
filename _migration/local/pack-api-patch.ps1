<#
  pack-api-patch.ps1 - build a lightweight "API patch" for the local SmartTDS install.

  Instead of rebuilding the full Advanced Installer when only the API changed, this
  packs just the files that go OVER the install dir (normally api\SmartTdsApi.dll, plus
  any new migration .sql) into a zip, and writes the api-version.json manifest the
  desktop ApiUpdater reads. Upload BOTH to your updates host:
        https://www.<domain>.com/updates/api-version.json
        https://www.<domain>.com/updates/api-patch-<version>.zip

  The desktop ApiUpdater (frontend) then: stops the SmartTdsApi service, extracts the
  zip over the install dir, restarts it. The API self-applies pending migrations on
  startup (idempotent), so a patch that includes new migration .sql upgrades the schema
  on the restart - no full installer needed.

  Use -RequiresFullInstall for releases a patch CAN'T cover (new dependency DLL, a
  pgsql/runtime upgrade, a new PG extension) - the desktop then tells the user to run
  the full .aip instead.

  Zip layout (paths are install-dir-relative, matching how the desktop extracts):
      api\SmartTdsApi.dll
      api\<other changed files...>            (only if you pass -ExtraApiFiles)
      _migration\local\migrations\<new>.sql   (only if you pass -Migrations)

  Run:
    powershell -ExecutionPolicy Bypass -File _migration\local\pack-api-patch.ps1 `
       -ApiDist "_migration\local\dist\api" -OutDir "_migration\local\dist\patch" `
       -Notes "Lock Year fix + grid filter"
#>
[CmdletBinding()]
param(
  [string]   $ApiDist        = (Join-Path $PSScriptRoot "dist\api"),  # published API folder
  [string]   $OutDir         = (Join-Path $PSScriptRoot "dist\patch"),
  [string[]] $ExtraApiFiles  = @(),                  # extra changed files under \api (e.g. a new dep dll)
  [string[]] $Migrations     = @(),                  # explicit .sql names; EMPTY = all in MigrationsDir NOT in the .aip baseline
  [string]   $MigrationsDir  = (Join-Path $PSScriptRoot "migrations"),
  [string]   $BaselineFile   = (Join-Path $PSScriptRoot "aip-baseline.txt"), # migrations the base .aip already ships (skip these)
  [string[]] $Scripts        = @(),                  # changed _migration\local\*.ps1 to include (e.g. backup-local.ps1)
  [string]   $ScriptsDir     = $PSScriptRoot,        # where those .ps1 live
  [switch]   $RequiresFullInstall,
  [string]   $Notes          = ""
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
# .NET APIs (ZipFile.CreateFromDirectory, GetFileHash, etc.) resolve RELATIVE paths
# against the PROCESS working directory, which in PowerShell is NOT the shell's current
# location ($PWD). Sync them so relative -ApiDist / -OutDir behave as the user expects
# (otherwise "..\updates" resolved from the wrong base).
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)

$dll = Join-Path $ApiDist "SmartTdsApi.dll"
if (-not (Test-Path $dll)) { throw "SmartTdsApi.dll not found in $ApiDist. Run publish-local.ps1 first." }

# version = the dll's FileVersion (driven by <Version> in SmartTdsApi.csproj)
$ver = (Get-Item $dll).VersionInfo.FileVersion
if (-not $ver) { throw "Could not read FileVersion from $dll" }
Write-Host ">> API version: $ver" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path          # absolute, so the zip/stage paths are unambiguous
$stage = Join-Path $OutDir ("_stage_" + $ver)
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $stage "api") | Out-Null

# always include the main assembly
Copy-Item $dll (Join-Path $stage "api\SmartTdsApi.dll") -Force
# optional extra api files (changed deps, apphost exe, etc.)
foreach ($f in $ExtraApiFiles) {
  $src = Join-Path $ApiDist $f
  if (-not (Test-Path $src)) { throw "ExtraApiFiles: not found in dist - $f" }
  Copy-Item $src (Join-Path $stage "api\$f") -Force
  Write-Host "   + api\$f" -ForegroundColor DarkGray
}
# optional changed scripts (_migration\local\*.ps1) — land next to the API on apply
if ($Scripts.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path (Join-Path $stage "_migration\local") | Out-Null
  foreach ($s in $Scripts) {
    $src = Join-Path $ScriptsDir $s
    if (-not (Test-Path $src)) { throw "Script not found - $src" }
    Copy-Item $src (Join-Path $stage "_migration\local\$s") -Force
    Write-Host "   + _migration\local\$s" -ForegroundColor DarkGray
  }
}
# migrations — ship every migration the base installer (.aip) does NOT already bundle, so a
# client that skips intermediate patches still receives them (e.g. jumping 1.0.7 -> 1.1.0 must
# still get master__0005 traces from 1.0.8), WITHOUT re-shipping the foundational schema the
# .aip already carries. The excluded set lives in aip-baseline.txt (refresh it when you rebuild
# the .aip). Everything is idempotent + schema_migrations-tracked, so a stray one would no-op.
$migsToPack = if ($Migrations.Count -gt 0) {
  $Migrations
} else {
  $baseline = @()
  if (Test-Path $BaselineFile) {
    $baseline = @(Get-Content $BaselineFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith("#") })
  }
  @(Get-ChildItem -Path $MigrationsDir -Filter *.sql -File |
      Sort-Object Name |
      Select-Object -ExpandProperty Name |
      Where-Object { $baseline -notcontains $_ })
}
if ($migsToPack.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path (Join-Path $stage "_migration\local\migrations") | Out-Null
  foreach ($m in $migsToPack) {
    $src = Join-Path $MigrationsDir $m
    if (-not (Test-Path $src)) { throw "Migration not found - $src" }
    Copy-Item $src (Join-Path $stage "_migration\local\migrations\$m") -Force
    Write-Host "   + _migration\local\migrations\$m" -ForegroundColor DarkGray
  }
}

$zip = Join-Path $OutDir ("api-patch-$ver.zip")
if (Test-Path $zip) { Remove-Item $zip -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip)
Remove-Item $stage -Recurse -Force

$sha  = (Get-FileHash $zip -Algorithm SHA256).Hash
$size = (Get-Item $zip).Length
# stdsapiN.txt — line-based, parallel to the app's stdsN.txt:
#   1 version | 2 url | 3 filename | 4 size | 5 sha256 | 6 requiresFullInstall(1/0) | 7+ notes
$reqFlag = if ($RequiresFullInstall) { "1" } else { "0" }
$lines = @(
  $ver,
  ("api-patch-$ver.zip"),     # url (relative to the updates base; desktop resolves it)
  ("api-patch-$ver.zip"),     # filename
  "$size",
  $sha,
  $reqFlag
)
if ($Notes) { $lines += ("Changes ${ver}:"); $lines += (" " + $Notes) }
$manifestPath = Join-Path $OutDir "stdsapiN.txt"
($lines -join "`r`n") | Set-Content -Path $manifestPath -Encoding ASCII

Write-Host ""
Write-Host ">> DONE" -ForegroundColor Green
Write-Host ("   zip : {0}  ({1:N1} KB)" -f $zip, ((Get-Item $zip).Length/1KB))
Write-Host ("   sha : {0}" -f $sha)
Write-Host ("   man : {0}" -f $manifestPath)
Write-Host ""
Write-Host "Upload BOTH to: https://www.<domain>.com/updates/  (api-version.json + the zip)" -ForegroundColor Yellow
if ($RequiresFullInstall) { Write-Host "NOTE: requiresFullInstall=TRUE - desktop will tell users to run the full installer." -ForegroundColor Yellow }
