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
  [string[]] $Migrations     = @(),                  # new migration .sql filenames to include
  [string]   $MigrationsDir  = (Join-Path $PSScriptRoot "migrations"),
  [string[]] $Scripts        = @(),                  # changed _migration\local\*.ps1 to include (e.g. backup-local.ps1)
  [string]   $ScriptsDir     = $PSScriptRoot,        # where those .ps1 live
  [switch]   $RequiresFullInstall,
  [string]   $Notes          = ""
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$dll = Join-Path $ApiDist "SmartTdsApi.dll"
if (-not (Test-Path $dll)) { throw "SmartTdsApi.dll not found in $ApiDist. Run publish-local.ps1 first." }

# version = the dll's FileVersion (driven by <Version> in SmartTdsApi.csproj)
$ver = (Get-Item $dll).VersionInfo.FileVersion
if (-not $ver) { throw "Could not read FileVersion from $dll" }
Write-Host ">> API version: $ver" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
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
# optional new migrations
if ($Migrations.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path (Join-Path $stage "_migration\local\migrations") | Out-Null
  foreach ($m in $Migrations) {
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
