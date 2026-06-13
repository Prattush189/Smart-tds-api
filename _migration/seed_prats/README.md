# seed_data_prats — customer data for the online server

Converts the SQL Server data dump (`~/Downloads/script.txt`) into PostgreSQL
seed files you can load onto the online (VPS) server's databases.

## Files
| file | target DB | rows | contents |
|------|-----------|------|----------|
| `seed_data_prats_master.sql` | `masterdbtds` | 267 | assessee 57, bankdetails 92, consultant 31, assesseeresstatus 50, assesseerep 4, returndates 22, groups 8, billhead 1, billdetails 1, **users 1 (prats)** |
| `seed_data_prats_25.sql` | `smarttds25` | 3789 | tdsentry 1818, payee 1792, addchallan 170, + filingstatus/salary/tdscompincome/applicationparams |
| `seed_data_prats_26.sql` | `smarttds26` | 124 | payee 106, salary 4, tdscompincome 3, + addchallan/tdsentry/filingstatus/tdsdeduction/applicationparams |
| `convert_prats.py` | — | — | the converter (re-run to regenerate) |
| `load_seed_prats.sh` | — | — | loader (psql, one file per DB) |

## Data cleanup applied (important)
The raw dump's `bankdetails` (1,646 rows) lived in the **shared** `MasterDbTds`,
so it contained bank accounts for ~900 assessees while only 58 assessees were
exported. The converter therefore removes:
- **orphan rows** — any child row whose owner assessee isn't in the export
  (1,501 bankdetails + a few others), and
- **already soft-deleted rows** (`isdeleted=true`, treated as permanently gone)
  — incl. 1 soft-deleted assessee (its children cascade-dropped) and 53 bank rows.

Result: `bankdetails` 1,646 → **92** (only your 57 assessees' live accounts).
Re-running `convert_prats.py` reprints the kept/dropped breakdown.

## What the converter does (SQL Server → PostgreSQL)
- Strips `[dbo].` and `[brackets]`; lowercases all identifiers.
- `N'...'` → `'...'`; `CAST(N'...' AS DateTime)` → `'...'` (timestamp literal).
- Bare `0x` empty varbinary (`profilepic`) → `NULL`.
- `bit` `0/1` → `false/true` for boolean columns (PG16 has no implicit int→bool cast).
- Column-name fixes where the PG schema renamed source columns:
  `aadhaarEnrolment→aadhaarnrolment`, `aadhaarStatus→aadharstatus`,
  `leiValidUpto→leivaldupto`, `aoApprovalNo→aoapprovalnu`.
- Parses by the `GO` batch separator, so values with embedded newlines
  (consultant `logo`/`emailsignature`) are not split.
- Resets identity sequences at the end of each file.
- **`prats` user password** `&lt;prats-password&gt;` is re-hashed to PBKDF2-HMAC-SHA256
  (100k iterations) matching `SmartTdsApi/Auth/PasswordHasher.cs`, so it logs in.

## Reference/master tables are intentionally OMITTED
`country, state, district, tdsrate, tdsnature, tdsentriessection, tdsded80,
check_period, aymaster, applicationparams (master)` are **already seeded** by
`_migration/phase1/pg/03_master_seed_data.sql`. Re-inserting them would clash
on primary keys. (The master `applicationparams.auth` encryption key in the
dump is byte-identical to the already-seeded one, so nothing is lost.)

## How to load onto the ONLINE (VPS) server
The VPS PostgreSQL listens on localhost only. Two options:

**A. psql on the VPS**
```bash
# copy the 3 .sql files + load_seed_prats.sh to the VPS, then:
sudo -u postgres bash load_seed_prats.sh
```

**B. DBeaver (SSH tunnel)** — open each file and run it against the matching
database (`seed_data_prats_master.sql` → `masterdbtds`, `_25` → `smarttds25`,
`_26` → `smarttds26`).

> Load order does not matter between databases. Within each file, foreign-key
> order is already correct (assessee→billhead→billdetails; salary→child rows).
> Each file is wrapped in a single transaction with `ON_ERROR_STOP`, so a
> failure rolls the whole file back — nothing partial.

## Login after loading
- `prats` / `&lt;prats-password&gt;`, licence (prodKey) **PYFA5V_1** — already the licence on
  the VPS. Note: ONLINE mode requires the prodKey to be recognised by the
  ServiceUL licence authority (the test key may fail gate 1); the existing
  `admin/&lt;admin-password&gt;` user remains available either way.
- Assessee portal passwords inside the data (e.g. `&lt;portal-password&gt;`) are stored as-is
  (plain data, not API logins) — unchanged.

## Re-generating
```bash
python3 convert_prats.py
```
Reads `C:\Users\Prattush\Downloads\script.txt`, writes the three `.sql` files.

## Validation done
Loaded into a throwaway PostgreSQL 16 (Docker `sttest`) built with the exact
migration schema — all three files applied with `ON_ERROR_STOP=1` and **zero
errors**; row counts, boolean conversion, `profilepic` NULLs, and the
`prats` PBKDF2 hash (verified against `&lt;prats-password&gt;`) all confirmed.
