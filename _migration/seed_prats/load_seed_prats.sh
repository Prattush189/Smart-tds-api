#!/usr/bin/env bash
# Load the SmartTds customer seed data into PostgreSQL.
# Run on the VPS (or any host) where the three databases already exist with
# the migration schema applied (02/03 master + 01 year template).
#
# Usage:
#   ./load_seed_prats.sh                      # local socket, user postgres
#   PGUSER=postgres PGHOST=127.0.0.1 PGPORT=5432 ./load_seed_prats.sh
#
# Each file runs inside its own BEGIN/COMMIT; -v ON_ERROR_STOP=1 aborts the
# whole file on any error (nothing partially loaded).
set -euo pipefail
cd "$(dirname "$0")"
PSQL="psql -v ON_ERROR_STOP=1 -q"

echo "== masterdbtds =="; $PSQL -d masterdbtds -f seed_data_prats_master.sql
echo "== smarttds25  =="; $PSQL -d smarttds25  -f seed_data_prats_25.sql
echo "== smarttds26  =="; $PSQL -d smarttds26  -f seed_data_prats_26.sql
echo "DONE."
