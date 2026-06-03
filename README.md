# Smart eTDS — Central API (server)

Server-side of the SmartTds migration: a central **ASP.NET Core 8** API over **PostgreSQL**, replacing per-site SQL Server. The WinForms desktop talks only to this API.

> This repo contains **only what runs on / sets up the server** — the API and the DB/deploy scripts. The desktop app and other solution projects live in the separate (SVN) working copy.

## Layout
```
SmartTdsApi/                ASP.NET Core API (JWT auth, licensing, year→DB routing, Npgsql/Dapper)
_migration/
  phase1/pg/                PostgreSQL schema + reference data (master + per-year template)
  phase1/run_pg_migration.ps1   build all DBs locally (Docker)
  phase5/                   least-privilege role + licensing tables
  tools/                    create_user.ps1 / create_licence.ps1
  deploy/                   DEPLOY_VPS.md, setup_vps_db.sh, smarttds-api.service, deploy.ps1
  README.md                 master migration guide
```

## Deploy
- **Provision the DB:** `_migration/deploy/setup_vps_db.sh` (creates DBs, schema, reference data, licensing, least-priv role).
- **Deploy the API:** `_migration/deploy/deploy.ps1` (publish → scp → restart) or the manual steps in `_migration/deploy/DEPLOY_VPS.md`.
- **Config/secrets:** set on the server via `smarttds.env` (env vars override `appsettings.json`); never committed.

Live: `https://api.smartbizin.com` · health: `/health` · API docs: `/swagger` (Development only).

## Notes
- `appsettings.json` holds **dev defaults only** (localhost DB, placeholder JWT). Production **requires** real `Db__Password` + `Jwt__Key` via env — the API refuses to start otherwise.
- Tenancy: shared `masterdbtds` + one `smarttds<YY>` per assessment year; the API routes by the `X-Assessment-Year` header.
