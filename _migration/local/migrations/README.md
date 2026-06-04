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

## How they reach each environment
**Local and the VPS are independent islands** — nothing syncs between them. A
migration must be *delivered as a file* and *run* in each place separately.

### Local installs (delivered by SmartUpdater, applied automatically)
1. **Fetch:** ship the new `migrations\*.sql` inside the SmartUpdater update package
   (vendor packaging). SmartUpdater overwrites them into the install on next launch.
2. **Run (automatic, no reinstall, no new exe for schema-only changes):**
   - the desktop calls `POST /api/migrate` right after login (`MigrateApi.Run()`), and
   - the local API also runs them on **service startup** (`RunMigrationsOnStartup`).
   Both invoke `migrate-local.ps1` (as the `postgres` superuser); it's idempotent.
3. Or on a full installer run, `install-local.ps1` → `migrate-local.ps1`.

Manual: `powershell -ExecutionPolicy Bypass -File ..\migrate-local.ps1`

### VPS (cloud)
Not auto-applied by deploy (by choice). Apply on the server when you ship a schema
change: `sudo -u postgres psql -d <db> -f <master|year file>` (or run
`migrate-local.ps1`'s logic via psql). The API runs as least-privilege and cannot
perform DDL, so migrations are a privileged step.

(No migrations exist yet — the baseline schema is current. Add the first one when a
schema change ships.)
