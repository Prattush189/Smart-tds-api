# Row-Level Security (RLS) — tenant isolation behind the API

Defense-in-depth: even if an API query forgets `WHERE prodkey=…`, PostgreSQL only
returns/accepts rows owned by the current tenant. The API stays the boundary; RLS
is the safety net underneath it.

## How it works
- The API sets a per-request GUC **`app.prodkey`** on every DB connection
  (`DbConnectionFactory` → `set_config('app.prodkey', <jwt prodkey>, false)`, read
  from the JWT via `IHttpContextAccessor`). It's set on *every* `OpenAsync`, so a
  pooled connection can never carry a stale tenant.
- Policies in `03_rls_master.sql` scope each tenant table to `app.prodkey`.
- **Unset/empty → default deny** (`current_setting('app.prodkey', true)` is NULL →
  policy false → 0 rows). A missing tenant can never leak data.
- Enforced on the least-privilege role **`smarttds_app`** (not owner, not BYPASSRLS).
  **`postgres`** (table owner) bypasses RLS, so migrations / seed / `pg_dump` /
  `pg_restore` still work normally.

## Covered (master DB)
- prodkey-owned: `assessee`, `consultant`, `groups`
- subcode-owned (via `assessee.prodkey`): `bankdetails`, `assesseerep`,
  `assesseeresstatus`, `returndates`, `feepaidmarking`, `billhead`, `billmast`, `billreceipt`
- billid-owned (via `billhead`): `billdetails`, `billreceipts`

## NOT covered (by design)
- `users` / `licences` / `sessions` — auth infra; login reads them *before* a JWT
  exists, so RLS there would break login. Protected by the auth logic + prodkey filters.
- reference tables (`country`, `state`, `district`, `tdsrate`, …) — shared, read-only.
- **Year DBs (`smarttds<YY>`)** — not yet. Those tables have no `prodkey` column
  (only `subcode`), and `assessee` lives in the master DB (no cross-DB join). A
  follow-up can add RLS there via an `app.subcodes` GUC the API sets per request, or
  a denormalized `prodkey` column. For now year data is scoped by the API's `subcode`
  filter.

## Applying it
- **New installs:** automatic — `provision-local.ps1` and `run_pg_migration.ps1` apply
  `03_rls_master.sql` (idempotent: `DROP POLICY IF EXISTS` + `CREATE OR REPLACE`).
- **Existing local installs:** re-running provisioning applies it.
- **VPS (existing, has data):** apply once, **AFTER deploying the new API**:
  ```bash
  # 1. deploy the API that sets app.prodkey (REQUIRED FIRST)
  cd /www/wwwroot/smarttds-src && git pull --ff-only && bash _migration/deploy/deploy-server.sh
  # 2. then enable RLS
  sudo -u postgres psql -d masterdbtds -f _migration/phase5/03_rls_master.sql
  ```
  ⚠️ **Order matters.** If you enable RLS while the *old* API (which doesn't set
  `app.prodkey`) is still running, every tenant query returns 0 rows and the app
  shows no data. Deploy the new API first.

## Notes
- Small per-query cost: one extra round-trip per connection open to set the GUC.
  Negligible for normal use; can be batched later if a hot path needs it.
- Verified in Docker: owner sees all; `smarttds_app` sees only its `app.prodkey`
  tenant; unset → 0 rows; child tables scoped via `app_owns_subcode`.
