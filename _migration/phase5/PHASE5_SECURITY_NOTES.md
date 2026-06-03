# Phase 5 — Security & Hardening  ✅ (implemented in API, validated live)

Hardening was built into the API from the start, then validated against the running service.

## Implemented & validated
| Control | Implementation | Validation |
|---|---|---|
| **Least-privilege DB role** | `smarttds_app`: CRUD only, NO DDL/DROP/TRUNCATE, no superuser. `01_least_privilege_role.sql` (per-DB grants + default privileges so new year DBs auto-grant) | ✅ CRUD works; `CREATE TABLE`→*permission denied*, `DROP`→*must be owner* |
| **No client DB credentials** | desktop holds only API URL + JWT (Phase 3); kills hardcoded `sa`/`pass.123` | ✅ slice runs with zero DB creds in client |
| **Password hashing** | PBKDF2-HMAC-SHA256 replaces plaintext/DES | ✅ login verifies; wrong pw → 401 |
| **Brute-force protection** | rate limiter: login policy 8/min per IP; global 120/10s | ✅ 8 attempts then **429** |
| **SQL injection** | all queries parameterized (Dapper); year value digit-sanitized before DB-name interpolation | ✅ |
| **Secret hygiene** | `Jwt:Key` + `Db:Password` via env/secret store; **fail-fast** if weak/default JWT key outside Development | ✅ throws on startup with bad key |
| **No error leakage** | global exception handler → clean JSON, full detail only in logs | ✅ unknown year → friendly 404, no stack trace |
| **Security headers** | `X-Content-Type-Options`, `X-Frame-Options:DENY`, `Referrer-Policy` | ✅ present on responses |
| **CORS** | deny by default; allow-list via `Cors:Origins` | ✅ |
| **Audit logging** | login success/failure logged with username | ✅ |

## Deployment-time items (server, Phase 6)
- **HTTPS / Let's Encrypt** terminated at HAProxy (Phase 4 config); API behind it. TLS 1.2+ only.
- **Firewall**: Postgres reachable ONLY from the API subnet (Phase 4 runbook). PgBouncer/HAProxy the only public surfaces.
- Rotate `smarttds_app` password + JWT key from the CHANGE_ME placeholders; store in the secret manager.
- Confirm **no `DataSet` is ever deserialized from a client** (Phase 0 confirmed none in API path).

## Carry-forward (tie-ins to other phases)
- **Legacy password migration**: on first successful login against an old hash, re-hash to PBKDF2 (transitional verifier accepts both). Needed when real `users` rows migrate.
- **Session tracking** (replaces `sys.dm_exec` `ActiveSessions`): track active sessions in the API (e.g. a sessions table / cache keyed by JWT jti) for seat enforcement.
- **`MAX+1` id generation** → Postgres sequences (concurrency + integrity), do during Phase 3 billing port.

## Files
- `01_least_privilege_role.sql` — the app role + grants.
- Hardening code: `SmartTdsApi/Program.cs` (rate limiter, headers, CORS, exception handler, JWT-key guard), `SmartTdsApi/Endpoints/AuthEndpoints.cs` (audit + login throttle), `SmartTdsApi/Auth/PasswordHasher.cs`.
