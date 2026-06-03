# Phase 2 — API Layer  ✅ (vertical slice validated end-to-end on live PG 16)

ASP.NET Core 8 Web API in [`SmartTdsApi/`](../../SmartTdsApi). Proven against the Dockerized Postgres (`sttest`, port 55432) with real auth, year→DB routing, and tenant filtering.

## What was built
| Concern | Implementation | File |
|---|---|---|
| Year→DB routing | `OpenMasterAsync()` / `OpenYearAsync(year)`; year is the routing key, never a tenant | `Data/DbConnectionFactory.cs` |
| Data access | Npgsql + Dapper, parameterized queries, slim DTOs | `Endpoints/*`, `Models/Dtos.cs` |
| Auth | JWT bearer; token carries identity/`prodkey`, NOT the year | `Auth/JwtTokenService.cs` |
| Passwords | PBKDF2-HMAC-SHA256 (replaces legacy plaintext/DES) | `Auth/PasswordHasher.cs` |
| Config/secrets | bound from `Db`/`Jwt` sections, env-overridable (`Db__Password`, `Jwt__Key`) | `appsettings.json`, `Program.cs` |
| API docs | Swagger UI with bearer auth | `Program.cs` |

## Endpoints (the slice: Login → Assessee → Challan)
- `POST /api/auth/login` → `{token, expiresUtc, name, userType}` (anonymous)
- `GET /api/assessees` / `GET /api/assessees/{subCode}` — from **master DB** (shared)
- `GET /api/challans?subCode=N` + header `X-Assessment-Year: 26` — from **year-routed DB** `smarttds26`
- `GET /health` (anonymous)

## Test results (all green)
| # | Check | Result |
|---|---|---|
| 1 | health | ok |
| 2 | no token → protected route | 401 ✅ |
| 3 | login (admin / Test@123) | JWT issued ✅ |
| 4 | wrong password | 401 ✅ |
| 5 | assessees (master DB) | 2 rows ✅ |
| 6 | challans y26 sub1 (smarttds26) | 2 rows ✅ |
| 7 | challans y26 sub2 | 1 row ✅ (firm filtering within year DB) |
| 8 | unknown year (smarttds99) | 404 + friendly message ✅ |
| 9 | missing year header | 400 ✅ |

## How to run locally
```powershell
# Postgres must be up (run_pg_migration.ps1 builds the DBs); then load dev data:
#   _migration/phase2/dev_seed.sql  (user admin / Test@123, 2 assessees, 3 challans)
cd SmartTdsApi
$env:ASPNETCORE_ENVIRONMENT="Development"
dotnet run --urls http://localhost:5080
# Swagger: http://localhost:5080/swagger
```

## Security wins delivered (vs legacy)
- Client will hold **only API URL + JWT** — zero DB credentials (kills hardcoded `sa`/`pass.123`).
- Passwords hashed (PBKDF2), not plaintext/DES.
- All queries parameterized via Dapper (addresses the Phase 0 string-concat injection sites as they're ported).
- Year normalization guards against injection into the DB name.

## Carry-forward into Phase 3 (client refactor) & beyond
- **Coarse-grained endpoints**: the #1 perf trap (Phase 0 risk #6). A screen that made 30 in-process DB calls must become ~1 API call. Design endpoints per-screen, not per-query.
- **Legacy password migration**: re-hash to PBKDF2 on first successful login (needs a verifier that also accepts old hashes during transition).
- **Two Phase-0 design items still open**: cross-DB 3-part name (`[MasterDbTds]…TdsEntriesSection` in TdsPayeeBal) → API reads master + year via separate connections; `sys.dm_exec` session query (UsersBal) → app/API-tracked sessions.
- **`MAX+1` id generation** (BillHead etc.) → Postgres sequences before deadline-scale concurrency.
- Least-privilege PG role (not `postgres`) for the real deployment; per-env secrets.
