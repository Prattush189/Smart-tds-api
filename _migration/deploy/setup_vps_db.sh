#!/usr/bin/env bash
# Provision PostgreSQL for SmartTds on the VPS: databases + schema + reference
# data + licensing + least-privilege role + grants. Idempotent-ish (safe to re-run).
#
# PREREQS: PostgreSQL 16 installed (aaPanel App Store) and you know the postgres
#          superuser password.
# USAGE (from the uploaded _migration folder):
#   export PGSUPERPW='your_postgres_superuser_password'
#   export APP_PW='strong_password_for_smarttds_app'      # must match smarttds.env Db__Password
#   bash deploy/setup_vps_db.sh
set -euo pipefail

MIG="${MIG:-$(cd "$(dirname "$0")/.." && pwd)}"   # the _migration folder
APP_PW="${APP_PW:?set APP_PW to the smarttds_app role password}"
export PGPASSWORD="${PGSUPERPW:?set PGSUPERPW to the postgres superuser password}"
PSQL="psql -h 127.0.0.1 -U postgres -v ON_ERROR_STOP=1 -q"
YEARS="${YEARS:-25 26}"

echo ">> databases"
$PSQL -tc "SELECT 1 FROM pg_database WHERE datname='masterdbtds'" | grep -q 1 || $PSQL -c "CREATE DATABASE masterdbtds"
for y in $YEARS; do
  $PSQL -tc "SELECT 1 FROM pg_database WHERE datname='smarttds$y'" | grep -q 1 || $PSQL -c "CREATE DATABASE smarttds$y"
done

echo ">> app role (smarttds_app)"
$PSQL -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='smarttds_app') THEN CREATE ROLE smarttds_app LOGIN PASSWORD '$APP_PW' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION; ELSE ALTER ROLE smarttds_app PASSWORD '$APP_PW'; END IF; END \$\$;"

echo ">> master schema + reference data + licensing"
$PSQL -d masterdbtds -f "$MIG/phase1/pg/02_master_schema.sql"
$PSQL -d masterdbtds -f "$MIG/phase1/pg/03_master_seed_data.sql"
$PSQL -d masterdbtds -f "$MIG/phase5/02_licensing.sql"

echo ">> per-year templates"
for y in $YEARS; do $PSQL -d "smarttds$y" -f "$MIG/phase1/pg/01_smarttds_year_template.sql"; done

echo ">> grants (least privilege)"
for db in masterdbtds $(for y in $YEARS; do echo smarttds$y; done); do
  $PSQL -d "$db" -v "dbname=$db" -f "$MIG/phase5/01_least_privilege_role.sql"
done

echo
echo "DONE. Next: seed a licence + user, e.g."
echo "  psql -h 127.0.0.1 -U postgres -d masterdbtds -f lic.sql"
echo "  psql -h 127.0.0.1 -U postgres -d masterdbtds -f admin_user.sql"
echo "(generate lic.sql / admin_user.sql on Windows with create_licence.ps1 / create_user.ps1  -Container '')"
