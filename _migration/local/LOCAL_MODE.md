# SmartTds — Two deployment modes (Local LAN / Online cloud)

The *identical* SmartTds stack (desktop + API + PostgreSQL) ships in two modes. The
desktop only ever talks to "an API"; the only differences are config + packaging.

| | **Local** | **Online** |
|---|---|---|
| Runs on | a server machine on the client's LAN (can be exposed to the internet too) | our cloud VPS |
| Data | local PostgreSQL (the 3 DBs) | cloud PostgreSQL |
| **Licence** | API → smartbizin **ServiceUL.svc** (machine-bound) | API → smartbizin **ServiceUL.svc** |
| **User login** | username/password vs the **local** DB | username/password vs the **cloud** DB |
| **Seats** | **unlimited** | enforced (cap from the cloud `licences` table) |

### System requirements (decided 2026-06-04)
- **Server machine** (runs API + PostgreSQL): **Windows 10/11 or Server 2016+** — required by
  .NET 8 + modern PostgreSQL. (Win7 is NOT supported for the server; .NET 8 dropped it.)
- **Client PCs** (run only the desktop app over the LAN): **Windows 7 SP1+** is fine — the
  WinForms app is .NET Framework 4.5.2, already Win7-compatible. They just need `ApiBaseUrl`
  pointed at the server's LAN IP.
- Single-PC installs therefore need that one PC to be Win10+. (If a customer ever needs the whole
  stack on a lone Win7 box, the fallback is retargeting the API to .NET 6 + PostgreSQL 13 — both EOL.)

**Licence validation** is the legacy `ServiceUL.svc` check, now done **server-side in the API**
(replaces the old desktop `Pump.cs`). The API computes a stable, persisted **machineId** and binds
the licence to it (Local = strict one-key-one-server; Online tolerates a key already bound to
another machine — shared cloud). See `SmartTdsApi/Auth/LicenceService.cs`.

> **One codebase.** App, BAL, and API are byte-for-byte identical online vs local.
> The only differences are *configuration* (base URL, DB host) and *packaging*.

```
  ONLINE (central)                         LOCAL (standalone)
  ┌────────────┐  HTTPS   ┌─────────┐      ┌────────────┐  HTTP   ┌──────────────┐
  │ Desktop app│ ───────▶ │  VPS    │      │ Desktop app│ ──────▶ │ local API svc│
  │ (VS2022)   │          │  API    │      │ (VS2022)   │ :5080   │ 127.0.0.1    │
  └────────────┘          │  +PG    │      └────────────┘         │   + PG :5433 │
       base URL =         └─────────┘           base URL =        └──────────────┘
   api.smartbizin.com                         127.0.0.1:5080       (private data)
```

## Phases

- **L1 — API on Windows (DONE).** API can host as a Windows Service
  (`builder.Host.UseWindowsService()`, no-op on the Linux VPS). `appsettings.Local.json`
  profile (env `ASPNETCORE_ENVIRONMENT=Local`) binds `http://127.0.0.1:5080`, points at
  a local PG on port **5433**, and selects offline licensing. `publish-local.ps1` builds a
  self-contained `win-x64` binary (no .NET install needed on the target).
- **L2 — Portable PostgreSQL + provisioning.** Bundle EDB portable Postgres, `initdb` to
  a per-machine data dir, run it on port 5433, then create `masterdbtds` + year DBs and
  apply the existing migration SQL + seed an admin user. (Reuses `_migration/phase1` scripts.)
- **L3 — ServiceUL licensing (DONE).** `Licensing:Mode` = `Local` | `Online`. The API's login is a
  3-gate flow: **(1) licence** via `ServiceUL.svc` (`LicenceService` — SOAP `CheckOnlineNoIP`,
  primary+fallback URLs, machine-bound, success cached `RecheckHours`); **(2) user** username/password
  vs the DB (both modes); **(3) seat** — Online only, cap read from the `licences` table
  (`prodkey → max_seats`, `is_active`); Local = unlimited. `LoginResponse` carries registered-to +
  expiry from ServiceUL. See `SmartTdsApi/Auth/LicenceService.cs`, `LicensingOptions.cs`,
  `Endpoints/AuthEndpoints.cs`. Config lives in `appsettings.json` (Mode=Online) and
  `appsettings.Local.json` (Mode=Local). `provision-local.ps1` seeds a bootstrap **admin user**
  locally (prodkey = the firm's real Licence Key) but **no `licences` row** (Local has no seat cap).
  > **Heads-up:** the Licence Key entered at login must be a REAL key that ServiceUL recognises.
  > The old test key `PYFA5V_1` only exists in our `licences` table, NOT in ServiceUL — it will fail
  > the gate now. On the cloud, set `Licensing:MachineIdFile` to a writable path (machineId persist).
- **L4 — Desktop Mode switch.** `app.config` gains `Mode = Central | Local`; the client picks
  the base URL accordingly. Optional: try central, auto-fall-back to local.
- **L5 — Installer (REUSE Advanced Installer).** Keep the existing Advanced Installer
  projects in `C:\SmartTds Backup\Depolyment` (the tool is ideal here: native Windows-service
  install, custom actions, firewall, prerequisites). Reuse breakdown:
  - **SmartTDS.aip** (app) — ~90% reusable. Refresh payload from the new VS2022 build, add
    `SmartTds.ApiClient.dll` (+deps), swap in the new `SmartTdsWinUI.exe.Config` (Mode + base URL).
  - **SmartTDS Database.aip** — GUT & REPLACE. It installs SQL Server Express 2008R2 + runs
    3 T-SQL scripts via a `(local)\SQLExpress` `sa` connection. For Postgres+API: bundle portable
    PostgreSQL + the published API, run `provision-local.ps1` (L2) as a custom action, register the
    API as a Windows service, add a firewall rule for the LAN port. Old T-SQL scripts in
    `Depolyment\SQL scripts\*.sql` are obsolete (superseded by `_migration/phase1/pg/*.sql`).
  - **SmartTDSPrerequisites.aip** — drop the SQL Server Express prereq; keep .NET 4.5.2
    (WinForms app needs it; the self-contained API needs none).
  - Optional: collapse all three into one installer for a cleaner customer experience.

## Data model (no sync)

Chosen 2026-06-04: client **data** is independent per install — its own PG + the 3 DBs, **no
sync** with central (avoids the entire change-tracking / conflict-resolution problem). The only
central dependency is **auth at login time**. So "local" = customers who keep their data on their
own hardware but are still licensed/seat-controlled centrally.

## Build/run cheat-sheet

```powershell
# L1: produce the self-contained API
pwsh _migration\local\publish-local.ps1            # -> _migration\local\dist\api\

# run it by hand (after L2 gives you a local PG on :5433)
$env:ASPNETCORE_ENVIRONMENT = "Local"
_migration\local\dist\api\SmartTdsApi.exe          # listens on http://127.0.0.1:5080
# smoke test:  curl http://127.0.0.1:5080/health
```
