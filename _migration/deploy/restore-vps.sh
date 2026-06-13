#!/usr/bin/env bash
# restore-vps.sh — restore SmartTds databases on the VPS from a backup archive
# made by backup-vps.sh. DESTRUCTIVE: drops & recreates the dumped DBs.
# Run as ROOT (needs systemctl + sudo -u postgres). Only touches SmartTds DBs.
#
#   bash _migration/deploy/restore-vps.sh /var/backups/smarttds/SmartTdsBackup_vps_YYYY_..._.tar.gz
#   bash _migration/deploy/restore-vps.sh <archive> --force      # skip the prompt
set -euo pipefail

ARCHIVE="${1:-}"
FORCE="${2:-}"
SERVICE="${SERVICE:-smarttds-api}"
REPO="${REPO:-/www/wwwroot/smarttds-src}"
GRANTS_SQL="${GRANTS_SQL:-$REPO/_migration/phase5/01_least_privilege_role.sql}"
BACKUP_SH="${BACKUP_SH:-/usr/local/bin/smarttds-backup.sh}"

[ -n "$ARCHIVE" ] || { echo "usage: $0 <archive.tar.gz> [--force]"; exit 1; }
[ -f "$ARCHIVE" ] || { echo "archive not found: $ARCHIVE"; exit 1; }
[ "$(id -u)" = "0" ] || { echo "run as root (needs systemctl + sudo -u postgres)"; exit 1; }

PG() { sudo -u postgres "$@"; }   # run a command as the postgres OS user (peer auth)

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
tar -xzf "$ARCHIVE" -C "$work"
dumps=("$work"/*.dump)
[ -e "${dumps[0]}" ] || { echo "no .dump files in archive"; exit 1; }

dbnames=(); for d in "${dumps[@]}"; do dbnames+=("$(basename "${d%.dump}")"); done
echo "Will OVERWRITE: ${dbnames[*]}"
if [ "$FORCE" != "--force" ]; then
  read -r -p "Type RESTORE to proceed: " ans
  [ "$ans" = "RESTORE" ] || { echo "aborted."; exit 0; }
fi

# safety backup of the current state first
if [ -x "$BACKUP_SH" ]; then echo ">> safety backup"; PG bash "$BACKUP_SH" || true; fi

echo ">> stopping $SERVICE"; systemctl stop "$SERVICE" || true

for d in "${dumps[@]}"; do
  db="$(basename "${d%.dump}")"
  echo ">> restoring $db"
  PG psql -d postgres -v ON_ERROR_STOP=1 -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$db' AND pid<>pg_backend_pid();" >/dev/null
  PG psql -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $db;" -c "CREATE DATABASE $db;"
  # pg_restore exits non-zero even on benign --no-owner notices, so a non-zero code is
  # not proof of failure — but a real error must NOT be reported as "RESTORE COMPLETE".
  if ! out="$(PG pg_restore -d "$db" --no-owner --no-privileges "$d" 2>&1)"; then
    if echo "$out" | grep -qiE 'pg_restore: error:|^[[:space:]]*error:'; then
      echo "$out" >&2
      echo ">> RESTORE FAILED for '$db' — database may be incomplete. Aborting (a prerestore safety backup was taken)." >&2
      systemctl start "$SERVICE" || true
      exit 1
    fi
    echo "$out"   # warnings only — non-fatal
  fi
  if [ -f "$GRANTS_SQL" ]; then
    PG psql -d "$db" -v dbname="$db" -v ON_ERROR_STOP=1 -f "$GRANTS_SQL" >/dev/null
  else
    echo "   (grants file not found at $GRANTS_SQL - re-grant smarttds_app manually)"
  fi
done

echo ">> starting $SERVICE"; systemctl start "$SERVICE" || true
sleep 1; echo -n "health: "; curl -s http://127.0.0.1:5080/health || true; echo
echo "RESTORE COMPLETE: ${dbnames[*]}"
