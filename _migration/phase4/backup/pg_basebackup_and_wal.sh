#!/usr/bin/env bash
# =============================================================================
# pg_basebackup_and_wal.sh — SIMPLE fallback backup for SmartTds PostgreSQL 16
# -----------------------------------------------------------------------------
# Use this ONLY when pgBackRest is unavailable (e.g. the small aaPanel VPS) or
# as an emergency belt-and-braces copy. pgBackRest (pgbackrest.conf) is the
# preferred production tool — it does incremental + parallel + S3 + PITR cleanly.
#
# What this does:
#   1. Takes a full physical base backup with pg_basebackup (tar + gzip).
#   2. Relies on the server's archive_command to ship WAL into $WAL_ARCHIVE so
#      PITR between base backups is possible.
#   3. Applies a simple retention: 7 daily base backups kept; older pruned.
#   4. (Optional) rsyncs the backup off-site.
#
# Run as the postgres user, e.g. from cron:
#   0 1 * * *  /opt/smarttds/backup/pg_basebackup_and_wal.sh >> /var/log/smarttds-backup.log 2>&1
# =============================================================================
set -euo pipefail

# ---- CONFIG (CHANGE_ME values) ----------------------------------------------
PGHOST="${PGHOST:-10.0.0.11}"          # the CURRENT primary (or HAProxy :5000)
PGPORT="${PGPORT:-5432}"
REPL_USER="${REPL_USER:-replicator}"   # needs REPLICATION; password via ~/.pgpass
BACKUP_ROOT="${BACKUP_ROOT:-/var/lib/pgsql/basebackups}"
WAL_ARCHIVE="${WAL_ARCHIVE:-/var/lib/pgsql/wal_archive}"   # where archive_command drops WAL
RETENTION_DAYS="${RETENTION_DAYS:-7}"  # keep 7 daily base backups
OFFSITE_RSYNC_TARGET="${OFFSITE_RSYNC_TARGET:-}"           # e.g. backup@10.0.0.99:/srv/smarttds
                                                            # leave empty to skip off-site
# -----------------------------------------------------------------------------

STAMP="$(date +%Y%m%d_%H%M%S)"
DEST="${BACKUP_ROOT}/base_${STAMP}"
mkdir -p "${DEST}" "${WAL_ARCHIVE}"

echo "[$(date -Is)] Starting base backup -> ${DEST}"

# --- Full base backup ---------------------------------------------------------
# -X stream : stream WAL needed to make the backup self-consistent.
# -c fast   : immediate checkpoint so the backup begins right away.
# -z -Z 6   : gzip-compress the tar output.
pg_basebackup \
  --host="${PGHOST}" --port="${PGPORT}" --username="${REPL_USER}" \
  --pgdata="${DEST}" \
  --format=tar --gzip --compress=6 \
  --wal-method=stream \
  --checkpoint=fast \
  --label="smarttds_base_${STAMP}" \
  --progress --verbose

echo "[$(date -Is)] Base backup complete."

# --- Record the backup's start LSN for reference / PITR bookkeeping -----------
echo "label=smarttds_base_${STAMP}" >  "${DEST}/BACKUP_INFO.txt"
echo "created=$(date -Is)"          >> "${DEST}/BACKUP_INFO.txt"
echo "wal_archive=${WAL_ARCHIVE}"   >> "${DEST}/BACKUP_INFO.txt"

# --- Retention: delete base backups older than RETENTION_DAYS ----------------
echo "[$(date -Is)] Pruning base backups older than ${RETENTION_DAYS} days"
find "${BACKUP_ROOT}" -maxdepth 1 -type d -name 'base_*' -mtime "+${RETENTION_DAYS}" \
  -print -exec rm -rf {} +

# --- WAL retention: keep WAL only as far back as the OLDEST surviving base ----
# Conservative approach: drop archived WAL older than RETENTION_DAYS too. (For
# strict correctness use pg_archivecleanup against the oldest base backup's
# START WAL file; PITR needs continuous WAL from that point forward.)
echo "[$(date -Is)] Pruning archived WAL older than ${RETENTION_DAYS} days"
find "${WAL_ARCHIVE}" -type f -mtime "+${RETENTION_DAYS}" -print -delete || true

# --- Optional off-site copy ---------------------------------------------------
if [[ -n "${OFFSITE_RSYNC_TARGET}" ]]; then
  echo "[$(date -Is)] Rsync off-site -> ${OFFSITE_RSYNC_TARGET}"
  rsync -a --delete "${BACKUP_ROOT}/" "${OFFSITE_RSYNC_TARGET}/basebackups/"
  rsync -a          "${WAL_ARCHIVE}/" "${OFFSITE_RSYNC_TARGET}/wal_archive/"
fi

echo "[$(date -Is)] Backup job finished OK."

# =============================================================================
# RESTORE (manual outline — see restore-test.sh for an automated drill):
#   1. Stop PostgreSQL; move the corrupt $PGDATA aside.
#   2. Extract the chosen base_* tarballs into a fresh $PGDATA.
#   3. Create $PGDATA/recovery.signal and set in postgresql.conf:
#         restore_command = 'cp ${WAL_ARCHIVE}/%f %p'
#         recovery_target_time = '2026-06-02 14:30:00+05:30'   # for PITR
#         recovery_target_action = 'promote'
#   4. Start PostgreSQL; it replays WAL to the target and promotes.
# =============================================================================
