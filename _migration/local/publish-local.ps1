<#
  publish-local.ps1 — build the SmartTds API as a self-contained Windows binary
  for the STANDALONE LOCAL install (no .NET runtime needed on the target PC).

  Output: _migration\local\dist\api\  (SmartTdsApi.exe + all deps + appsettings*.json)

  Usage:
    pwsh _migration\local\publish-local.ps1
    pwsh _migration\local\publish-local.ps1 -Configuration Release -SelfContained:$false
#>
param(
  [string]$Configuration = "Release",
  [switch]$SelfContained = $true,
  [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = Resolve-Path (Join-Path $here "..\..")
$proj   = Join-Path $root "SmartTdsApi\SmartTdsApi.csproj"
$outDir = Join-Path $here "dist\api"

Write-Host "Publishing API ($Configuration / $Runtime, self-contained=$SelfContained)..." -ForegroundColor Cyan

if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }

$args = @(
  "publish", $proj,
  "-c", $Configuration,
  "-r", $Runtime,
  "--self-contained", $SelfContained.ToString().ToLower(),
  "-o", $outDir,
  "/p:PublishSingleFile=false",
  "/p:DebugType=none"
)
& dotnet @args
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed ($LASTEXITCODE)" }

Write-Host ""
Write-Host "DONE -> $outDir" -ForegroundColor Green
Write-Host "Next: install as a Windows service (see install-service.ps1) after L2 provisions PostgreSQL." -ForegroundColor Yellow
