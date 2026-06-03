#!/usr/bin/env bash
# Server-side deploy: pull the repo, build, and swap into the run dir.
# Prereqs (one-time): .NET 8 SDK + git on the VPS; repo cloned; smarttds.env present in RUN_DIR.
# Usage:  cd <repo> && bash _migration/deploy/deploy-server.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../.." && pwd)"        # repo root
RUN_DIR="${RUN_DIR:-/www/wwwroot/smarttds-api}"
SERVICE="${SERVICE:-smarttds-api}"

echo ">> git pull";  cd "$SRC"; git pull --ff-only
echo ">> publish";   rm -rf /tmp/sttds-pub
dotnet publish "$SRC/SmartTdsApi/SmartTdsApi.csproj" -c Release -r linux-x64 --self-contained true -o /tmp/sttds-pub
echo ">> stop";      systemctl stop "$SERVICE"
echo ">> swap (preserving smarttds.env)"
find "$RUN_DIR" -mindepth 1 -maxdepth 1 ! -name smarttds.env -exec rm -rf {} +
cp -r /tmp/sttds-pub/* "$RUN_DIR/"
chmod +x "$RUN_DIR/SmartTdsApi"
echo ">> start";     systemctl start "$SERVICE"; sleep 1
echo -n "health: ";  curl -s http://127.0.0.1:5080/health; echo
echo ">> DONE"
