# SmartTds backup & restore (PostgreSQL)

Replaces the old SQL-Server `FrmBackup` (`BACKUP DATABASE … TO DISK` → `.bak`),
which does not work against PostgreSQL. Backups are now logical dumps via
`pg_dump -Fc`, bundled into one timestamped zip per run, with a rolling version
history.

> **Local mode only.** Online (the shared VPS cluster) is backed up server-side
> (pgBackRest/cron, Phase 4) — the API backup endpoints refuse in Online mode so
> one firm can't dump the shared multi-tenant DB.

## Pieces
| file | role |
|------|------|
| `backup-local.ps1` | dump `masterdbtds` + every `smarttds<YY>` (`pg_dump -Fc`) → `SmartTdsBackup_<label>_<ts>.zip` + manifest; prune to last *N* of that label |
| `restore-local.ps1` | restore a backup zip: safety-backup → stop API → drop/recreate each DB → `pg_restore` → re-grant `smarttds_app` → start API |
| `SmartTdsApi/Endpoints/BackupEndpoints.cs` | API: `POST /api/backups`, `GET /api/backups`, `GET /api/backups/{file}`, `POST /api/backups/{file}/restore` (admin + Local only) |
| `install-service.ps1` | registers a **daily** Windows Scheduled Task `SmartTds Daily Backup` (08:00 PM, keep 30) |
| `SmartTdsWinUI/Common/BackupApi.cs` | desktop helper: `BackupApi.Create()/List()/Restore()` via the API |

Backups land in `C:\ProgramData\SmartTds\backups\` by default.

## Versioning / retention
Each run writes a new `SmartTdsBackup_<label>_<yyyy_MM_dd_HH_mm_ss>.zip`. Retention
is **per label**: daily keeps the last `-Keep` (30) dailies; manual (in-app)
backups are kept separately; a `prerestore` safety copy is auto-made before every
restore. So you always have a rolling history, never a single overwrite.

## Triggers
1. **In-app Backup button** → `BackupApi.Create()` → `POST /api/backups`.
2. **"Backup and Exit"** (closing dialog) → same, in Local mode only.
3. **Daily scheduled task** → `backup-local.ps1 -Label daily` (runs even if the app is closed).

### Local-vs-online flag (`Variables.IsLocalServer`)
`SmartTdsOnline` is `true` in BOTH modes (the app always talks to an API), so it
can't gate backups. `FrmLogin` now sets `Variables.IsLocalServer = !_online`:
- **Online (cloud):** `FrmClosingDialog` hides "Backup and Exit" ("auto backup on server").
- **Local:** the button shows; `MainForm.MainForm_FormClosing` calls `BackupApi.Create()`.
Wired in: `Global/Variables.cs`, `Masters/Users/FrmLogin.cs`, `Utility/FrmClosingDialog.cs`,
`MainForm.cs` (rebuild in VS2022).

## Manual use (CLI)
```powershell
# backup now (keep last 30 manual)
powershell -ExecutionPolicy Bypass -File backup-local.ps1 -Label manual -Keep 30
# restore (DESTRUCTIVE)
powershell -ExecutionPolicy Bypass -File restore-local.ps1 -BackupZip "C:\ProgramData\SmartTds\backups\SmartTdsBackup_manual_2026_06_04_18_00_00.zip" -Force
```
Defaults: PG `127.0.0.1:5433`, superuser `postgres`/`postgres`, bin `…\SmartTds\pgsql\bin`.
If you provisioned with a non-default `-SuperPwd`, pass the same `-SuperPwd` here.

## Desktop wiring (VS2022)
Add these to `SmartTdsWinUI.csproj` (old-style project — new files aren't auto-included):
```xml
<Compile Include="Common\BackupApi.cs" />
<Compile Include="Utility\FrmBackupRestore.cs" />
```
- **Backup / Restore screen** = `Utility\FrmBackupRestore.cs` (code-only form, no Designer):
  lists backups, **Take Backup**, **Restore Selected** (with confirmation + auto safety
  backup). Uses `BackupApi.Create/List/Restore`.
- **Entry point:** `MainForm.AddBackupRestoreButton()` adds a **"Backup / Restore"** button
  to the **last ribbon tab** at runtime, **only in Local mode** (`Variables.IsLocalServer`).
  Online backups are server-side, so the button isn't shown there.
- Closing dialog "Backup and Exit" (local) calls `BackupApi.Create()` (already wired).
- The old `FrmBackup` (SQL Server) is superseded; you can leave it unreferenced or delete it.

## Installer (Advanced Installer "Database" project)
Add the two new scripts to the Files page under `_migration\local\`:
`backup-local.ps1`, `restore-local.ps1`. `install-local.ps1` → `install-service.ps1`
already registers the daily task automatically (pass `-NoBackupTask` to skip).

## Old SQL-Server `.bak` files
Not supported — `.bak` is SQL Server's binary format; PostgreSQL can't read it.
New clients are PostgreSQL-only, so there's no legacy import path. (A one-off
migration would need a SQL Server instance to read the `.bak`, then the
`convert_*` data pipeline.)
