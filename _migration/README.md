# SmartTds Migration — Master Guide & Next Steps

SQL Server (per-site) → central **PostgreSQL + ASP.NET Core API**, WinForms desktop talks only to the API.
This file is the entry point. To resume in a new session: *"Read `_migration/README.md` and continue."*

---

## 0. Where things stand

| Phase | Status | Artifacts |
|---|---|---|
| 0 Inventory | ✅ done | `phase0/PHASE0_INVENTORY.md` (+4 detail files) |
| 1 PG schema + reference data | ✅ validated on PG16 | `phase1/pg/*.sql`, `phase1/run_pg_migration.ps1` |
| 2 API layer | ✅ validated live | `../SmartTdsApi/`, `phase2/PHASE2_API_NOTES.md` |
| 3 Client refactor (foundation+slice) | ✅ validated | `../SmartTds.ApiClient/`, `phase3/PHASE3_CLIENT_NOTES.md` |
| 4 HA infra (configs + core proof) | ✅ artifacts ready | `phase4/PHASE4_HA_RUNBOOK.md` (+configs) |
| 5 Security hardening | ✅ validated | `phase5/PHASE5_SECURITY_NOTES.md`, `phase5/01_least_privilege_role.sql` |
| 6 Deployment & cutover | ⏳ next | *this guide, Parts B–E* |

**Locked decisions:** PostgreSQL; tenancy = one DB per assessment year (`smarttds26`…) + shared `masterdbtds` (firm is a column); portal automation stays client-side.

---

## A. Resume the local dev loop (verify in ~2 minutes)

Prereqs: Docker Desktop running, .NET SDK (8 or 9).

```powershell
# 1. start a throwaway Postgres (if not already running)
docker run -d --name sttest -e POSTGRES_PASSWORD=pw -p 55432:5432 postgres:16

# 2. build master + per-year DBs (years 25 & 26) with required reference data
_migration\phase1\run_pg_migration.ps1                 # defaults to years 25,26
#   more years:  _migration\phase1\run_pg_migration.ps1 -Years 25,26,27

# 3. issue a licence (the API is the licence authority), then a user under it
_migration\tools\create_licence.ps1 -ProdKey TEST123 -RegisteredTo "Acme & Co, CAs" -MaxSeats 2
_migration\tools\create_user.ps1    -Username admin -Password 'Test@123' -ProdKey TEST123
#   prodKey = the firm's Licence Key. non-admin: add -UserType USER -Admin:$false
#   for the VPS: add  -Container ''  to either script to emit a .sql you run there with psql

# 4. run the API  (Swagger at http://localhost:5080/swagger)
cd SmartTdsApi
$env:ASPNETCORE_ENVIRONMENT="Development"; dotnet run --urls http://localhost:5080

# 5. (new terminal) smoke test — pass user + licence key — expect ALL CLIENT TESTS PASSED
dotnet run --project SmartTds.ApiClient.SmokeTest -- http://localhost:5080 admin 'Test@123' TEST123
```
> No test fixtures are loaded — DBs hold only required reference data. Assessees/challans
> come from real use (or the data migration in §C); the smoke test asserts the endpoints
> respond and route by year, not specific row counts.

---

## B. Deploy the STAGING stack to your VPS (4-core/8GB Linux + aaPanel, ~5–10 users)

This is single-node (no HA yet) — right for testing. HA comes in Part E.
> **Concrete, copy-paste version with ready scripts:** [`deploy/DEPLOY_VPS.md`](deploy/DEPLOY_VPS.md)
> (includes `deploy/setup_vps_db.sh`, `deploy/smarttds-api.service`, `deploy/smarttds.env.example`).
> The API is .NET → run as a **systemd service** + aaPanel **reverse proxy**, NOT a Node project.

### B1. Install PostgreSQL 16 on the VPS
- **aaPanel route:** App Store → install **PostgreSQL 16** (or "PgSQL Manager"). Set a strong superuser password.
- **CLI route (Debian/Ubuntu):**
  ```bash
  sudo apt install -y postgresql-common && sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
  sudo apt install -y postgresql-16
  ```
- Apply the small-VPS tuning block from `phase4/postgres/postgresql.tuned.conf` (the `4c/8GB` override: `shared_buffers=1GB`, `effective_cache_size=4GB`, `max_connections=100`). Reload.

### B2. Create role + databases + schema (run as the PG superuser, e.g. `psql`)
```bash
# copy the SQL files to the VPS first (scp / aaPanel file manager), into ~/sttds/
psql -f phase5/01_least_privilege_role.sql            # creates smarttds_app (set a real password!)
createdb masterdbtds && createdb smarttds25 && createdb smarttds26
psql -d masterdbtds -f phase1/pg/02_master_schema.sql
psql -d masterdbtds -f phase1/pg/03_master_seed_data.sql
psql -d smarttds25  -f phase1/pg/01_smarttds_year_template.sql
psql -d smarttds26  -f phase1/pg/01_smarttds_year_template.sql
# grant the app role on each DB:
for db in masterdbtds smarttds25 smarttds26; do psql -d $db -v dbname=$db -f phase5/01_least_privilege_role.sql; done
```
Add a year later = `createdb smarttds27` + run the template + the grant for it.

### B2b. Apply licensing schema, then create licences + users (on the VPS)
```bash
psql -d masterdbtds -f phase5/02_licensing.sql      # licences + sessions tables
```
Generate licence + user SQL on your dev box, copy over, run with psql:
```powershell
_migration\tools\create_licence.ps1 -ProdKey PYFA5V_1 -RegisteredTo "Acme & Co" -MaxSeats 5 -Container '' -OutFile .\lic.sql
_migration\tools\create_user.ps1    -Username admin -Password 'StrongPass#1' -ProdKey PYFA5V_1 -Container '' -OutFile .\admin_user.sql
#  -> scp lic.sql admin_user.sql to the VPS, then:
#     psql -d masterdbtds -f lic.sql && psql -d masterdbtds -f admin_user.sql
```
Seed the `licences` table from your existing licence records (key, registered-to, expiry, seats).

### B3. Publish & deploy the API
On your Windows dev box — **self-contained** so the VPS needs no .NET install:
```powershell
cd SmartTdsApi
dotnet publish -c Release -r linux-x64 --self-contained true -o publish_linux
# upload the publish_linux/ folder to the VPS, e.g. /www/smarttds-api/
```
On the VPS, create a systemd service `/etc/systemd/system/smarttds-api.service`:
```ini
[Unit]
Description=SmartTds API
After=network.target postgresql.service
[Service]
WorkingDirectory=/www/smarttds-api
ExecStart=/www/smarttds-api/SmartTdsApi
Restart=always
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://127.0.0.1:5080
Environment=Db__Host=127.0.0.1
Environment=Db__Port=5432
Environment=Db__Username=smarttds_app
Environment=Db__Password=THE_REAL_APP_PASSWORD
Environment=Jwt__Key=GENERATE_A_LONG_RANDOM_64_CHAR_SECRET
[Install]
WantedBy=multi-user.target
```
```bash
chmod +x /www/smarttds-api/SmartTdsApi
sudo systemctl daemon-reload && sudo systemctl enable --now smarttds-api
curl http://127.0.0.1:5080/health      # {"status":"ok",...}
```
> Production mode **requires** a strong `Jwt__Key` (the app refuses to start otherwise) and disables Swagger.

### B4. HTTPS + public reverse proxy (aaPanel)
- aaPanel → Website → add a site/subdomain (e.g. `api.yourdomain.com`).
- Set **Reverse Proxy** → target `http://127.0.0.1:5080`.
- Enable **SSL → Let's Encrypt** (auto-renew). Force HTTPS.
- Firewall: allow 443 only; keep Postgres (5432) bound to localhost / internal — never public.

### B5. Point the desktop at the API
In `SmartTdsWinUI\app.config`:
```xml
<add key="UseApi" value="true"/>
<add key="ApiBaseUrl" value="https://api.yourdomain.com"/>
```
Add the `AppApi` accessor and the strangler branches per `phase3/PHASE3_CLIENT_NOTES.md`.

**Staging exit:** desktop logs in over HTTPS and loads the Assessee + Challan screens through the API.

---

## C. Migrate real firm data (when ready)
The schema + reference data are done; transactional firm data still needs a source.
1. Export data from live `SmartTds26` (+ in-use `MasterDbTds` firm rows): SSMS *Generate Scripts → data only*, **or** bcp/CSV.
2. Convert with the same pattern as `phase1/convert_seed.ps1` (de-bracket, `N'`→`'`, bit→bool, lowercase identifiers).
3. Load, then **reconcile**: row counts + a checksum per table vs the SQL Server source.
4. Reset identity sequences (`setval(pg_get_serial_sequence(...))`) — see `03_master_seed_data.sql` footer.

---

## D. Finish the client port (the bulk — mechanical, behind the flag)
Worklist = the 190 BAL methods in `phase0/PHASE0_INVENTORY.md`. For each screen:
1. **Build ONE coarse API endpoint** that returns everything the screen needs (avoid 30 WAN round-trips — the #1 perf trap).
2. Add the method to `IApiClient`/`ApiClient`.
3. Branch the screen on `AppApi.UseApi` (keep the BAL path for rollback).
4. Test against staging; then remove the legacy DB path.

Order: masters/reference → Payee/TdsEntry/Salary → Billing (**fix `MAX+1`→sequences here**) → cross-DB `TdsPayeeBal` → finally delete the client's hardcoded connection string.

Also during the port: **legacy password re-hash on first login**, and **API session tracking** (replaces `sys.dm_exec` seat logic).

---

## E. Graduate to production HA (when users/uptime demand it)
Everything is in `phase4/`. Summary:
- Primary + standby, **synchronous** streaming replication (RPO 0), auto-failover via **Patroni + etcd**.
- **PgBouncer** (transaction pooling) in front — essential for deadline login storms.
- **2 API nodes** behind **HAProxy** (stateless/JWT). Read/write split: writes→leader, read-heavy screens→standby.
- **pgBackRest**: full+incremental + WAL archiving + off-site, with a periodic restore drill.
- Sizing for deadline spikes: primary+standby **8 vCPU / 32 GB / NVMe**.
- ⚠️ Verify the image tags in `docker-compose.ha.yml` before `docker compose up`. Follow `phase4/PHASE4_HA_RUNBOOK.md` deployment-day checklist.

---

## Verification checklist (each environment)
- [ ] `curl /health` ok
- [ ] login returns a token; wrong password → 401; >8 logins/min → 429
- [ ] assessees load (master DB); challans load with `X-Assessment-Year` header (year DB)
- [ ] API connects as `smarttds_app` (NOT superuser); `CREATE TABLE` denied
- [ ] Postgres not reachable from the public internet
- [ ] strong `Jwt__Key` set; app started in Production mode
- [ ] (HA) `pg_stat_replication` shows streaming; failover tested with `patronictl switchover`

## Key facts cheat-sheet
- DBs: `masterdbtds` (shared) + `smarttds<YY>` per year. Routing key = assessment **year** (header `X-Assessment-Year`), never a tenant.
- Reserved columns needing quotes: `"limit"` (tdsentriessection, tdsrate), `"desc"` (f15hn).
- Login needs BOTH a licence and a user with `prodkey` = the firm's **Licence Key**. Create via `_migration/tools/create_licence.ps1` then `create_user.ps1`. The API is the licence authority (seats + expiry; see `phase5/LICENSING_NOTES.md`). Local PG: container `sttest`, port 55432, pw `pw`.
- `SCOPE_IDENTITY()`→`RETURNING`; money is `numeric` (not float); dates stored as `dd/MM/yyyy` text.
