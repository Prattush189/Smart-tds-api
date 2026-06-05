# SmartTds release checklist

What to do when shipping a change, so each environment actually receives it.
Local installs and the VPS are **independent islands** — apply to each separately.

Key rule: code lives in this git repo; **what reaches a local PC is decided by the
SmartUpdater package + the installer Files page** — those are packaging steps, not
code. If a file isn't in the package, the PC never gets it.

---

## A. Schema change (new column / table / index)
1. **Author** a migration in `_migration/local/migrations/`:
   - `master__NNNN__desc.sql` → applied to `masterdbtds`
   - `year__NNNN__desc.sql` → applied to every `smarttds<YY>`
   - Make it **idempotent** (`ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`)
     and **forward-only** (never edit a shipped migration).
   - If a new column should also exist in **future** year DBs, also add it to the
     baseline template `_migration/phase1/pg/01_smarttds_year_template.sql`.
2. **Local delivery** — include in BOTH:
   - the **Advanced Installer** `Database.aip` Files page (first-time installs), and
   - the **SmartUpdater update zip** on the vendor update server (existing installs).
   Files to ship: `_migration/local/migrations/` + `_migration/local/*.ps1`.
   → Existing installs auto-apply on next login (`MigrateApi.Run`) and on API
     service restart (`RunMigrationsOnStartup`). No new `.exe` needed for schema-only.
3. **VPS** — apply manually (the API is least-privilege and can't run DDL):
   ```bash
   sudo -u postgres psql -d masterdbtds -f master__NNNN__desc.sql
   sudo -u postgres psql -d smarttds26  -f year__NNNN__desc.sql   # repeat per year DB
   ```

## B. API code change (e.g. endpoints, business logic)
- **VPS:** `git push origin main` → on the VPS:
  `cd /www/wwwroot/smarttds-src && bash _migration/deploy/deploy-server.sh`
- **Local:** re-publish the API and ship it in the package:
  `powershell -ExecutionPolicy Bypass -File _migration/local/publish-local.ps1`
  → include the `api\` folder in the installer / SmartUpdater zip.

## C. Desktop (WinForms) change
- Rebuild `SmartTdsWinUI.exe` in **VS2022** (old-style csproj: hand-add any new
  `.cs`/dll — e.g. `Common\BackupApi.cs`).
- Ship via installer + SmartUpdater package.

---

## Installer (Database.aip) Files page — must contain
- `api\` (output of `publish-local.ps1`)
- `pgsql\` (portable PostgreSQL: bin + lib + share)
- `_migration\local\` → `provision-local.ps1`, `install-local.ps1`, `install-service.ps1`,
  `publish-local.ps1`, **`backup-local.ps1`**, **`restore-local.ps1`**, **`migrate-local.ps1`**,
  and the **`migrations\`** folder
- `_migration\phase1\pg\` (01/02/03 .sql)
- `_migration\phase5\` (01 grants, 02 licensing)

## One-time VPS setup still pending
- **Nightly backup** (the VPS has none yet):
  ```bash
  cp _migration/deploy/backup-vps.sh /usr/local/bin/smarttds-backup.sh && chmod +x /usr/local/bin/smarttds-backup.sh
  install -d -o postgres -g postgres /var/backups/smarttds
  echo '30 1 * * * postgres /usr/local/bin/smarttds-backup.sh >> /var/log/smarttds-backup.log 2>&1' > /etc/cron.d/smarttds-backup
  ```

## Verify after a release
- Local: log in → check the new schema/feature; confirm a backup zip appears in
  `C:\ProgramData\SmartTds\backups\`; `schema_migrations` lists the new file.
- VPS: `curl -s https://api.smartbizin.com/health`; spot-check the migration applied.
