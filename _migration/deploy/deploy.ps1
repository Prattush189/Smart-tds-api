<#
.SYNOPSIS
  One-command deploy of the SmartTds API to the VPS:
  publish (self-contained linux-x64) -> zip -> scp to VPS -> unzip -> restart service -> health check.
  No git, no .NET SDK on the VPS. Uses Windows' built-in OpenSSH (ssh/scp).

.PREREQS
  - SSH access from this PC to the VPS (root). Test once:  ssh -p <port> root@66.116.224.29
  - `unzip` present on the VPS (usually is; else: apt install unzip).
  - For PASSWORDLESS (recommended) set up a key once:
      ssh-keygen -t ed25519            # press enter through prompts
      type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh -p <port> root@66.116.224.29 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    After that, ssh/scp won't prompt for a password.

.EXAMPLE
  .\deploy.ps1                       # uses defaults below
  .\deploy.ps1 -Port 22 -VpsHost 66.116.224.29
#>
param(
    [string]$VpsHost = "66.116.224.29",
    [string]$VpsUser = "root",
    [int]   $Port    = 22,
    [string]$RemoteDir = "/www/wwwroot/smarttds-api",
    [string]$Service   = "smarttds-api"
)
$ErrorActionPreference = "Stop"
$api  = Join-Path $PSScriptRoot "..\..\SmartTdsApi"
$pub  = Join-Path $api "publish_linux"
$zip  = Join-Path $api "publish_linux.zip"

Write-Host "== publish ==" -ForegroundColor Cyan
dotnet publish (Join-Path $api "SmartTdsApi.csproj") -c Release -r linux-x64 --self-contained true -o $pub
if ($LASTEXITCODE -ne 0) { throw "publish failed" }

Write-Host "== zip ==" -ForegroundColor Cyan
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $pub "*") -DestinationPath $zip

Write-Host "== upload (scp) ==" -ForegroundColor Cyan
scp -P $Port $zip "${VpsUser}@${VpsHost}:/tmp/smarttds-publish.zip"
if ($LASTEXITCODE -ne 0) { throw "scp failed" }

Write-Host "== remote: unzip + restart + health ==" -ForegroundColor Cyan
# stop -> overwrite files -> chmod -> start -> health. smarttds.env is NOT in the zip, so it's preserved.
$remoteCmd = "systemctl stop $Service; " +
             "unzip -o /tmp/smarttds-publish.zip -d $RemoteDir >/dev/null; " +
             "chmod +x $RemoteDir/SmartTdsApi; " +
             "systemctl start $Service; sleep 1; " +
             "rm -f /tmp/smarttds-publish.zip; " +
             "echo -n 'health: '; curl -s http://127.0.0.1:5080/health; echo"
ssh -p $Port "${VpsUser}@${VpsHost}" $remoteCmd
if ($LASTEXITCODE -ne 0) { throw "remote deploy failed" }

Write-Host "`nDONE. API redeployed to https://api.smartbizin.com" -ForegroundColor Green
