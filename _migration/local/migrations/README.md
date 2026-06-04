# Local PostgreSQL schema migrations

Forward-only delta scripts applied by `migrate-local.ps1` to bring EXISTING local
installs up to the current schema when a new app version ships. (Replaces the old
SQL-Server `FrmUpdateDb` version-gated updates.)

## Naming
```
<target>__<NNNN>__<description>.sql
```
- `target` = `master` → applied to `masterdbtds`
- `target` = `year`   → applied to **every** `smarttds<YY>` database
- `NNNN`  = zero-padded sequence (0001, 0002, …); apply order = filename sort

Examples:
- `master__0001__add_assessee_remark.sql`
- `year__0001__add_tdsentry_isrevised.sql`

## Rules
- **Idempotent**: use `ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`,
  `CREATE INDEX IF NOT EXISTS`, etc. (The runner also wraps each file + its
  bookkeeping row in one transaction.)
- **Forward-only**: never edit an already-shipped migration; add a new one.
- Each applied file is recorded in `schema_migrations(filename, applied_on)` per DB,
  so it runs exactly once per database.
- Grants for `smarttds_app` are re-applied automatically after any migration runs.
- The year **template** (`../phase1/pg/01_smarttds_year_template.sql`) stays at the
  baseline; new year DBs are created from it and then brought current by the same
  `year__*` migrations.

## Running
`migrate-local.ps1` runs automatically from `install-local.ps1` (after provisioning)
on every install/update. Manual:
```powershell
powershell -ExecutionPolicy Bypass -File ..\migrate-local.ps1
```

(No migrations exist yet — the baseline schema is current. Add the first one when a
schema change ships.)
