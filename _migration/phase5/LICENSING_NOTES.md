# Licensing — now owned by the API  ✅ (validated live)

The legacy login had **two gates**: (1) `Pump` validated the licence key against smartbizindia.com's `ServiceUL.svc` (returning *Registered To* / expiry / "Product Key Already in use" seat checks) with an encrypted cache in `ApplicationParams`; (2) `UsersBal` checked username/password where `prodKey = licence key`. Passwords were **plaintext**.

We replaced the external licence service with **server-side licensing in the API**.

## Model (new tables in `masterdbtds`, `phase5/02_licensing.sql`)
- **`licences`**: `prodkey` (PK, = licence key, UPPER), `registered_to`, `licence_type` (Full/Demo), `expiry_date`, `max_seats`, `is_active`.
- **`sessions`**: `jti` (PK, = JWT id), `prodkey`, `username`, `machine`, `expires_on`, `last_seen` — central seat tracking (stateless-API friendly; replaces `sys.dm_exec`).

## Login flow (API `/api/auth/login`)
1. **Gate 1 — licence**: licence must exist, be active, and not expired → else **403**.
2. **Gate 2 — user**: `username` + **exact** `prodkey` match + PBKDF2 password → else **401**.
3. **Gate 3 — seat**: purge expired sessions; if active sessions for the licence ≥ `max_seats` → **403**.
4. Issue JWT (carries `jti`) + insert a `sessions` row. Response includes **RegisteredTo, LicenceType, LicenceExpiry, SeatsUsed/MaxSeats** (drives the desktop's "LICENSED TO … (UPTO …)" banner).
- **`/api/auth/logout`** deletes the session row → frees the seat.

## Validated
| Behavior | Result |
|---|---|
| valid licence + user | login OK, returns `registeredTo='Acme & Co, CAs'`, seats `1/2` |
| wrong/unknown licence | **403** |
| expired licence | **403** |
| seat limit (2 seats: A,B ok; C blocked; logout A; C ok) | **403 then OK** |
| bad password | **401** |

## Issuing licences & users (scripts)
```powershell
_migration\tools\create_licence.ps1 -ProdKey PYFA5V_1 -RegisteredTo "Acme & Co, CAs" -MaxSeats 5
_migration\tools\create_user.ps1   -Username admin -Password 'Strong#1' -ProdKey PYFA5V_1
#   VPS: add  -Container ''  to emit a .sql to run there with psql
```
**prodkey = the firm's Licence Key** (stored UPPER). Each user belongs to one licence.

## Mapping from the old login screen
| Old field | Now |
|---|---|
| Licence Key | sent as `prodKey`; validated by Gate 1; matches the user's `prodkey` |
| Registered To / expiry / Full-vs-Demo | returned by the API in the login response (from `licences`) |
| Mode / Server | gone — desktop holds only the API URL |
| seat / "already in use" | `sessions` + `max_seats` (Gate 3) |

## Carry-forwards
- **JWT vs session revocation**: logout frees the seat but the JWT stays valid until expiry. If you need instant kill, add middleware that checks the `jti` still exists in `sessions` per request (small cost). Acceptable for now given short token lifetime.
- **Legacy data migration**: existing SQL Server users have **plaintext** passwords → re-hash to PBKDF2 on first successful login (transitional verifier accepts plaintext once, then upgrades). Existing licence keys → seed the `licences` table from your current licence records.
- **Demo mode** specifics (feature limits) from the old `Pump` aren't ported — only the gate (type + expiry). Add feature flags if needed.
