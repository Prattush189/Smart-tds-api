#!/usr/bin/env bash
# backup-vps.sh — nightly logical backup of the SmartTds databases on the VPS.
# pg_dump -Fc each DB (masterdbtds + smarttds<YY>) into one timestamped tar.gz,
# with rolling retention. Run as the postgres OS user (local peer auth).
#
# Install (one-time), as root:
#   cp _migration/deploy/backup-vps.sh /usr/local/bin/smarttds-backup.sh
#   chmod +x /usr/local/bin/smarttds-backup.sh
#   install -d -o postgres -g postgres /var/backups/smarttds
#   # nightly at 01:30, as postgres:
#   echo '30 1 * * * postgres /usr/local/bin/smarttds-backup.sh >> /var/log/smarttds-backup.log 2>&1' \
#        > /etc/cron.d/smarttds-backup
#
# Manual run:  sudo -u postgres /usr/local/bin/smarttds-backup.sh
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/smarttds}"
KEEP="${KEEP:-30}"                       # how many nightly archives to retain
PSQL="${PSQL:-psql}"
PG_DUMP="${PG_DUMP:-pg_dump}"
PGHOST="${PGHOST:-/var/run/postgresql}"  # local socket (peer auth as postgres)
export PGHOST

mkdir -p "$BACKUP_DIR"
stamp="$(date +%Y_%m_%d_%H_%M_%S)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# discover the SmartTds databases
dbs="$("$PSQL" -tAc "select datname from pg_database where datname='masterdbtds' or datname like 'smarttds%' order by datname")"
[ -n "$dbs" ] || { echo "no SmartTds databases found"; exit 1; }

for db in $dbs; do
  echo "  dumping $db"
  "$PG_DUMP" -Fc -d "$db" -f "$work/$db.dump"
done

# manifest + single archive
{
  echo "product=SmartTds"
  echo "created=$stamp"
  echo "host=$(hostname)"
  echo "databases=$(echo $dbs | tr '\n' ' ')"
  echo "format=custom (pg_dump -Fc)"
} > "$work/manifest.txt"

archive="$BACKUP_DIR/SmartTdsBackup_vps_${stamp}.tar.gz"
tar -czf "$archive" -C "$work" .
echo "  -> $archive"

# record where/when in applicationparams (backupLoc + lastBackup) — read by the
# desktop's Backup/Restore screen. Best-effort: never fail the backup over this.
today="$(date +%d/%m/%Y)"
"$PSQL" -d masterdbtds -c "update applicationparams set value='${BACKUP_DIR}' where name='backupLoc'; insert into applicationparams(name,value) select 'backupLoc','${BACKUP_DIR}' where not exists (select 1 from applicationparams where name='backupLoc'); update applicationparams set value='${today}' where name='lastBackup'; insert into applicationparams(name,value) select 'lastBackup','${today}' where not exists (select 1 from applicationparams where name='lastBackup');" \
  || echo "  (warn) could not record backupLoc/lastBackup"

# retention: keep newest $KEEP archives
ls -1t "$BACKUP_DIR"/SmartTdsBackup_vps_*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do
  echo "  pruned $old"; rm -f "$old"
done

echo "DONE."
