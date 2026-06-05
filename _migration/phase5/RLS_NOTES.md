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
## Year DBs (`smarttds<YY>`) — covered via `app.subcodes`
Year tables have no `prodkey` (only `subcode`), and `assessee` is in master (no
cross-DB join). So the year tenant key is the GUC **`app.subcodes`** — the CSV of the
firm's assessee subcodes. The API sets it per year connection (`DbConnectionFactory`
fetches the firm's subcodes from master — itself prodkey-scoped — and `set_config`s
them). Policies in `04_rls_year.sql`:
- subcode-keyed: `payee`, `tdsentry`, `addchallan`, `salary`, `tdsdeduction`,
  `tdscompincome`, `filingstatus`, `ddodet`, `f15hn`, `f15hnpayee`
- salid-keyed (via `salary.subcode`): `salarynaturedetails`, `salaryexemptallowances`,
  `salaryperquisitedetails`
- `applicationparams` (year `ver` config, no subcode) left open.
Unset `app.subcodes` → default deny. Cost: one extra master query per year-connection
open to fetch subcodes (no cache → always fresh; add a short cache if a hot path needs it).

## Applying it
- **New installs:** automatic — `provision-local.ps1` and `run_pg_migration.ps1` apply
  `03_rls_master.sql` (idempotent: `DROP POLICY IF EXISTS` + `CREATE OR REPLACE`).
- **Existing local installs:** re-running provisioning applies it.
- **VPS (existing, has data):** apply once, **AFTER deploying the new API**:
  ```bash
  # 1. deploy the API that sets app.prodkey (REQUIRED FIRST)
  cd /www/wwwroot/smarttds-src && git pull --ff-only && bash _migration/deploy/deploy-server.sh
  # 2. then enable RLS — master, then each year DB
  sudo -u postgres psql -d masterdbtds -f _migration/phase5/03_rls_master.sql
  sudo -u postgres psql -d smarttds25  -f _migration/phase5/04_rls_year.sql
  sudo -u postgres psql -d smarttds26  -f _migration/phase5/04_rls_year.sql
  ```
  ⚠️ **Order matters.** If you enable RLS while the *old* API (which doesn't set
  `app.prodkey`) is still running, every tenant query returns 0 rows and the app
  shows no data. Deploy the new API first.

## Notes
- Small per-query cost: one extra round-trip per connection open to set the GUC.
  Negligible for normal use; can be batched later if a hot path needs it.
- Verified in Docker: owner sees all; `smarttds_app` sees only its `app.prodkey`
  tenant; unset → 0 rows; child tables scoped via `app_owns_subcode`.
