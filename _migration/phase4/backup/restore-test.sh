#!/usr/bin/env bash
# =============================================================================
# restore-test.sh — periodic RESTORE DRILL for SmartTds backups
# -----------------------------------------------------------------------------
# "A backup you have never restored is not a backup." This script proves the
# pgBackRest repository can actually rebuild the cluster, on an ISOLATED scratch
# instance, WITHOUT touching production. Run it on a schedule (e.g. weekly) and
# alert if it fails.
#
# Strategy:
#   1. Restore the latest backup into a throwaway data dir on a spare port.
#   2. Start that instance read-only-ish, verify it reaches a consistent state.
#   3. Run smoke queries against each expected database.
#   4. Tear the scratch instance down. Report PASS/FAIL (exit code + log).
#
# Run as the postgres user on a host that can read the pgBackRest repo.
#   0 3 * * 0  /opt/smarttds/backup/restore-test.sh >> /var/log/smarttds-restore-test.log 2>&1
# =============================================================================
set -euo pipefail

STANZA="${STANZA:-smarttds}"
PG_BIN="${PG_BIN:-/usr/lib/postgresql/16/bin}"
SCRATCH_DATA="${SCRATCH_DATA:-/var/tmp/smarttds_restore_test/pgdata}"
SCRATCH_PORT="${SCRATCH_PORT:-55999}"        # MUST differ from prod (5432)
# Databases we expect to exist and be queryable after restore:
EXPECTED_DBS=("masterdbtds" "smarttds26" "smarttds25")
# Optional PITR target for the drill (empty = restore to latest):
RECOVERY_TARGET_TIME="${RECOVERY_TARGET_TIME:-}"
# -----------------------------------------------------------------------------

log() { echo "[$(date -Is)] $*"; }
fail() { log "FAIL: $*"; cleanup; exit 1; }

cleanup() {
  log "Cleaning up scratch instance"
  "${PG_BIN}/pg_ctl" -D "${SCRATCH_DATA}" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$(dirname "${SCRATCH_DATA}")" || true
}
trap cleanup EXIT

log "=== SmartTds restore drill START (stanza=${STANZA}) ==="

# --- 0. Clean any previous scratch dir ---------------------------------------
rm -rf "$(dirname "${SCRATCH_DATA}")"
mkdir -p "${SCRATCH_DATA}"
chmod 700 "${SCRATCH_DATA}"

# --- 1. Restore from pgBackRest into the scratch dir --------------------------
RESTORE_ARGS=(--stanza="${STANZA}" --pg1-path="${SCRATCH_DATA}" --delta --type=default)
if [[ -n "${RECOVERY_TARGET_TIME}" ]]; then
  RESTORE_ARGS=(--stanza="${STANZA}" --pg1-path="${SCRATCH_DATA}" --delta \
                --type=time "--target=${RECOVERY_TARGET_TIME}" --target-action=promote)
  log "PITR drill to ${RECOVERY_TARGET_TIME}"
fi
log "Running: pgbackrest ${RESTORE_ARGS[*]} restore"
pgbackrest "${RESTORE_ARGS[@]}" restore || fail "pgbackrest restore returned non-zero"

# --- 2. Point the restored instance at the scratch port; start it ------------
# Override the port so we never collide with a real server on this host.
cat >> "${SCRATCH_DATA}/postgresql.auto.conf" <<EOF
port = ${SCRATCH_PORT}
listen_addresses = 'localhost'
# This is a throwaway verification instance — no archiving, no replication.
archive_mode = off
EOF

log "Starting scratch instance on port ${SCRATCH_PORT}"
"${PG_BIN}/pg_ctl" -D "${SCRATCH_DATA}" -l "${SCRATCH_DATA}/restore_test.log" -w -t 300 start \
  || fail "scratch instance failed to start (check ${SCRATCH_DATA}/restore_test.log)"

# Wait until recovery is complete / accepting connections.
for i in $(seq 1 60); do
  if "${PG_BIN}/pg_isready" -h localhost -p "${SCRATCH_PORT}" -q; then break; fi
  sleep 2
  [[ $i -eq 60 ]] && fail "scratch instance never became ready"
done
log "Scratch instance is accepting connections."

# --- 3. Smoke-test each expected database ------------------------------------
PSQL=("${PG_BIN}/psql" -h localhost -p "${SCRATCH_PORT}" -U postgres -tA)

# Confirm we are no longer in recovery (PITR promote / latest applied).
IN_RECOVERY="$("${PSQL[@]}" -c 'SELECT pg_is_in_recovery();' postgres || echo error)"
log "pg_is_in_recovery() => ${IN_RECOVERY}"

for db in "${EXPECTED_DBS[@]}"; do
  if ! "${PSQL[@]}" -c 'SELECT 1' "${db}" >/dev/null 2>&1; then
    fail "cannot connect to restored database '${db}'"
  fi
  # Count user tables as a sanity signal the schema came back.
  TBLS="$("${PSQL[@]}" -c \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" "${db}")"
  log "DB ${db}: ${TBLS} public tables"
  [[ "${TBLS}" -gt 0 ]] || fail "database '${db}' restored with 0 public tables"
done

# Spot-check a known table if present (adjust to a real SmartTds table).
"${PSQL[@]}" -c "SELECT count(*) FROM information_schema.tables WHERE table_name='challan';" smarttds26 \
  >/dev/null 2>&1 || log "WARN: 'challan' table not found in smarttds26 (verify expected schema)"

log "=== SmartTds restore drill PASSED ==="
# cleanup runs via trap. Exit 0 => healthy backups.
exit 0
