# Converting `SmartTDS Database.aip` → Local server installer (PostgreSQL + API)

Goal: turn the old SQL-Server-Express database installer into one that lays down
**portable PostgreSQL + the self-contained API + the scripts**, then runs **one**
custom action (`install-local.ps1`) that provisions the DB, installs the services,
and points the app at the local API.

> Do all of this in the **Advanced Installer GUI** (don't hand-edit the `.aip` XML).
> Keep the product identity (UpgradeCode/ProductName/icon) so upgrades work.

---

## Step 0 — Build the payloads first (on your dev PC)

```powershell
# self-contained API  ->  _migration\local\dist\api\
pwsh _migration\local\publish-local.ps1

# get portable PostgreSQL "binaries" zip (win-x64) from enterprisedb.com,
# extract it so you have a folder:  <somewhere>\pgsql\bin\postgres.exe ...
```

You now have two folders to bundle: `...\dist\api` and `...\pgsql`, plus the
`_migration` scripts/SQL already in the repo.

---

## Step 1 — REMOVE the SQL-Server pieces

In the project tree on the left:

- **Prerequisites** → delete **“SQL Server Express 2008R2 SP2”**. (Also delete
  **“.NET Framework 4.0”** here — this installer needs no .NET; the API is
  self-contained. .NET 4.5.2 for the desktop app belongs to `SmartTDS.aip`.)
- **SQL Databases** (a.k.a. *SQL Scripts/Servers*) → delete the connection
  **`PredefinedConnection` ((local)\SQLExpressGST, sa)** and the three scripts
  **MasterDbTdsScript / SmartTds25Script / SmartTds26Script** (and their replace
  tokens). The old `Depolyment\SQL scripts\*.sql` are obsolete.
- **Files and Folders** → you can delete the old empty `Db` folder if unused.

---

## Step 2 — ADD the new payload (Files and Folders)

Add these under **APPDIR** (keep the relative structure exactly):

| Add as folder under APPDIR | Source |
|---|---|
| `api\` | `_migration\local\dist\api\*` (published API) |
| `pgsql\` | your extracted portable PostgreSQL (so `APPDIR\pgsql\bin\postgres.exe` exists) |
| `_migration\local\` | `_migration\local\*.ps1` |
| `_migration\phase1\pg\` | `_migration\phase1\pg\*.sql` |
| `_migration\phase5\` | `_migration\phase5\*.sql` |

(Optional, for a **single-PC** installer: also add `SmartTdsWinUI.exe` + its DevExpress
DLLs + `SmartTdsWinUI.exe.Config` from `SmartTDS.aip` so one installer sets up the whole
machine. Client-only PCs keep using `SmartTDS.aip` pointed at the server's LAN IP.)

---

## Step 3 — One optional property (admin password)

The installer is **key-free** — the firm types its Licence Key on the app's login
screen and it **binds on first login** (no key needed during setup). So you only
*optionally* set the bootstrap admin password:

**Product Details → Properties** → add one **public** property (UPPERCASE):

- `ADMINPWD` = `admin`  (default bootstrap admin password; the seeded login is `admin` / `admin`)

(You can skip even this and let the default `Admin@123` apply.)

---

## Step 4 — The install custom action (the whole setup in one call)

**Custom Actions** → add **“Launch file” / “Run program”**:

- **File**: an existing file on target →
  `[System64Folder]WindowsPowerShell\v1.0\powershell.exe`
- **Arguments**:
  ```
  -ExecutionPolicy Bypass -NoProfile -File "[APPDIR]_migration\local\install-local.ps1" -Lan
  ```
  (drop `-Lan` for a single-PC install that needn't accept LAN clients; the Licence
  Key is NOT passed here — the firm enters it at first login)
- **Execution time / stage**: **“When the system is being modified (deferred)”**,
  **after `InstallFiles`**.
- **Run mode**: **“Run under the LocalSystem account with full privileges”** (elevated;
  needed for initdb, `sc create`, firewall, writing ProgramData).
- **Options**: **Wait for it to finish**; (optionally) *Fail installation if it returns
  a non-zero exit code*.
- **Condition**: `NOT Installed`

> Advanced Installer auto-creates the “property setter” that passes `[APPDIR]` and
> `[ADMINPWD]` into the deferred action — just reference them in Arguments as above.

---

## Step 5 — The uninstall custom action (remove services)

Add a second **Launch file** custom action:

- **File**: `[System64Folder]WindowsPowerShell\v1.0\powershell.exe`
- **Arguments**:
  ```
  -ExecutionPolicy Bypass -NoProfile -File "[APPDIR]_migration\local\install-local.ps1" -Uninstall
  ```
  > **Do NOT add `-AppDir "[APPDIR]"`** to either action — `[APPDIR]` ends in `\`, so
  > `"[APPDIR]"` becomes an escaped quote and corrupts the arguments. The script finds
  > its own folder automatically.
- **Execution time**: deferred, **LocalSystem**, **before `RemoveFiles`** (so the
  scripts still exist when it runs).
- **Condition**: `REMOVE="ALL"`

(PostgreSQL **data** is left intact on uninstall by design — the script only removes
the services. Add a manual `Remove-Item $env:ProgramData\SmartTds` step if you want a
full wipe.)

---

## Step 6 — Folders / permissions

- **APPDIR**: default is fine (`[ProgramFiles]\Smartbiz...` or the current
  `[WindowsVolume]\SmartTDS`). The DB data goes to `C:\ProgramData\SmartTds\` (created
  by the script), not APPDIR, so APPDIR can stay read-only.
- You don’t need the AI **Services** page or **SQL** page anymore — `install-local.ps1`
  registers the `SmartTdsPg` + `SmartTdsApi` services itself (via `sc.exe` / `pg_ctl`).
- Keep the **Firewall** allow-exceptions option if you like; the script also adds an
  explicit rule for the API port when `-Lan` is passed.

---

## Step 7 — Build & test

1. Build the MSI/EXE in Advanced Installer.
2. Install on a clean Windows VM (as admin). Watch the log at
   `C:\ProgramData\SmartTds\logs\install-local.log`.
3. Verify: `Get-Service SmartTdsPg, SmartTdsApi` are **Running**; browse
   `http://127.0.0.1:5080/health`.
4. Launch the desktop app → log in with the firm's **real Licence Key** + the admin
   user. (Licence is checked against ServiceUL; data is local; seats unlimited.)

---

## What each script does (recap)

| Script | Role |
|---|---|
| `publish-local.ps1` | builds the self-contained API (dev PC, Step 0) |
| `install-local.ps1` | **the one custom action** — orchestrates the three below |
| `provision-local.ps1` | initdb private cluster, create the 3 DBs + schema/seed, seed admin user |
| `install-service.ps1` | register PostgreSQL + API as auto-start Windows services (+firewall) |
