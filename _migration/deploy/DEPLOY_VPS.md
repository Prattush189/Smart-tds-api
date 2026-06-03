# Deploy SmartTds API to the aaPanel VPS (66.116.224.29)

The API is **.NET (ASP.NET Core)** — run it as a **systemd service**, then point a domain at it via aaPanel's reverse proxy. NOT a Node project.

## What goes on the VPS
| Folder | Contents |
|---|---|
| `/www/wwwroot/smarttds-api/` | the **published self-contained API** (+ `smarttds.env`) |
| `/www/wwwroot/smarttds-sql/_migration/` | the **`_migration` folder** (SQL scripts + deploy scripts) |

---

## Step 1 — Publish the API (on your Windows dev box)
```powershell
cd "C:\SmartTds Backup\ProjectTDS - SQL\SmartTdsApi"
dotnet publish -c Release -r linux-x64 --self-contained true -o publish_linux
```
Upload `publish_linux\*` → `/www/wwwroot/smarttds-api/` (aaPanel → Files, or FTP).
Upload the whole `_migration` folder → `/www/wwwroot/smarttds-sql/_migration/`.

## Step 2 — PostgreSQL (aaPanel)
- aaPanel → **App Store** → install **PostgreSQL 16**. Note the `postgres` superuser password.
- (Optional tuning) apply the 4c/8GB block from `_migration/phase4/postgres/postgresql.tuned.conf`.

## Step 3 — Create DBs + schema + role (aaPanel → Terminal)
```bash
cd /www/wwwroot/smarttds-sql/_migration
chmod +x deploy/setup_vps_db.sh
export PGSUPERPW='your_postgres_superuser_password'
export APP_PW='choose_a_strong_app_db_password'      # remember this for Step 5
bash deploy/setup_vps_db.sh
```
This creates `masterdbtds` + `smarttds25/26`, loads schema + reference data + licensing, and the `smarttds_app` least-privilege role.

## Step 4 — Seed a licence + user
On Windows, emit the SQL (no Docker), upload, run:
```powershell
_migration\tools\create_licence.ps1 -ProdKey PYFA5V_1 -RegisteredTo "Your Firm" -MaxSeats 5 -Container '' -OutFile lic.sql
_migration\tools\create_user.ps1    -Username admin -Password 'StrongPass#1' -ProdKey PYFA5V_1 -Container '' -OutFile admin_user.sql
```
Upload `lic.sql` + `admin_user.sql` to the VPS, then:
```bash
psql -h 127.0.0.1 -U postgres -d masterdbtds -f lic.sql
psql -h 127.0.0.1 -U postgres -d masterdbtds -f admin_user.sql
```

## Step 5 — Run the API as a service
```bash
cd /www/wwwroot/smarttds-api
cp /www/wwwroot/smarttds-sql/_migration/deploy/smarttds.env.example smarttds.env
nano smarttds.env          # set Db__Password (= APP_PW from step 3) and a real Jwt__Key (openssl rand -base64 48)
chmod 600 smarttds.env
chmod +x SmartTdsApi
cp /www/wwwroot/smarttds-sql/_migration/deploy/smarttds-api.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now smarttds-api
systemctl status smarttds-api --no-pager
curl http://127.0.0.1:5080/health        # -> {"status":"ok",...}
```
If it dies with an ICU/globalization error: uncomment the `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` line in the service file, `daemon-reload`, restart.

## Step 6 — Expose it publicly
**Recommended (domain + HTTPS):**
1. DNS: add an A record `tds.smartbizin.com` → `66.116.224.29`.
2. aaPanel → **Website → Add site** (domain `tds.smartbizin.com`), or **Proxy Project**.
3. Set **Reverse Proxy** → target `http://127.0.0.1:5080`.
4. Enable **SSL → Let's Encrypt**, force HTTPS.
→ Desktop connects to **`https://tds.smartbizin.com`**.

**Quick test (no domain, temporary):** set `ASPNETCORE_URLS=http://0.0.0.0:5080` in `smarttds.env`, restart, open port **5080** in aaPanel → Security. Desktop connects to **`http://66.116.224.29:5080`**. (Switch back to `127.0.0.1` + proxy for real use.)

## Step 7 — Point the desktop at the API
`SmartTdsWinUI\app.config`:
```xml
<add key="UseApi" value="true"/>
<add key="ApiBaseUrl" value="https://tds.smartbizin.com"/>   <!-- or http://66.116.224.29:5080 for the quick test -->
```
On the login screen, the **Licence Key** field must equal the licence's `prodKey` (e.g. `PYFA5V_1`).

## Security checklist
- [ ] PostgreSQL **not** exposed publicly (firewall: only the API/localhost reaches 5432).
- [ ] `smarttds.env` is `chmod 600`; real `Jwt__Key` + `Db__Password` set (not CHANGE_ME).
- [ ] HTTPS on; port 5080 NOT open to the world once the reverse proxy is used.
- [ ] App runs as `smarttds_app` (least privilege), never the postgres superuser.

## Updating later
Re-publish → upload to `/www/wwwroot/smarttds-api/` → `systemctl restart smarttds-api`.
