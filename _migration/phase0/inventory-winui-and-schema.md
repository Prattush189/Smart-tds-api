# Phase 0 Migration Inventory — WinUI Direct DB Access & Schema

Generated: 2026-06-02

---

## Part A — Direct DB Access in WinUI

### Summary

17 direct-DB sites across 5 source files. None go through the BAL/DAL layer;
all open their own `SqlConnection` with a raw connection string built at call site.

| # | Site (file:line) | What it does | Bypasses BAL? |
|---|-----------------|--------------|---------------|
| 1 | `Global\Pump.cs:116-120` | `CheckIfTableExists()` — queries `INFORMATION_SCHEMA.TABLES` for `ApplicationParams` to gate table creation | YES |
| 2 | `Global\Pump.cs:140-149` | `CreateAuthIfNotExists()` — SELECT + conditional INSERT into `ApplicationParams` for the `auth` row | YES |
| 3 | `Global\Pump.cs:169-204` | `ReadFromDb()` — SELECT `ApplicationParams.value` where name='auth'; if table missing: CREATE TABLE + INSERT | YES |
| 4 | `Global\Pump.cs:226-242` | `WriteToDb()` — UPDATE `ApplicationParams` auth row; on truncation error: ALTER TABLE column to `nvarchar(MAX)` | YES |
| 5 | `Utility\FrmUpdateDb.cs:66-92` | `GetVersionInfo()` — SELECT `ApplicationParams` ver row; table missing path: CREATE TABLE `ApplicationParams` + INSERT | YES |
| 6 | `Utility\FrmUpdateDb.cs:115-118` | `CheckIfTableExists()` (duplicate of Pump) — `INFORMATION_SCHEMA.TABLES` check | YES |
| 7 | `Utility\FrmUpdateDb.cs:136-144` | `UpdateVersionInfo()` — UPDATE `ApplicationParams` set ver + showNewUpdates | YES |
| 8 | `Utility\FrmBackup.cs:163-171` | `Takebackup()` — `BACKUP DATABASE [...] to Disk` SQL Server-specific backup command | YES |
| 9 | `Utility\FrmBackup.cs:192-223` | `WriteToLogFile()` — enables `Ole Automation Procedures` via `sp_configure`, `sp_OACreate/sp_OAMethod` to write a log file via SQL Server OLEDB automation | YES |
| 10 | `Utility\FrmBackup.cs:379-392` | `GetBackupLoc()` — SELECT + INSERT `ApplicationParams` backupLoc row (MasterDbTds DB) | YES |
| 11 | `Utility\FrmBackup.cs:413-417` | `SetBackupLoc()` — UPDATE `ApplicationParams` backupLoc (MasterDbTds DB) | YES |
| 12 | `Utility\FrmBackup.cs:438-445` | `UpdateBackupDate()` — MERGE pattern: IF EXISTS UPDATE ELSE INSERT `ApplicationParams` lastBackup (SQL Server T-SQL `IF EXISTS` syntax) | YES |
| 13 | `Utility\FrmBackup.cs:463-467` | `GetBackupDate()` — SELECT `ApplicationParams` lastBackup | YES |
| 14 | `Common\DbScope.cs:141-153` | `DatabaseExistsForAy()` — opens `master` DB, queries `sys.databases` WHERE name = SmartTds{NN}; result is cached for session | Partial (infra helper used by BAL calls) |
| 15 | `MasterDbTdsDataSet.Designer.cs:2880-3032` | Typed DataSet TableAdapter for **BillDetails** — full CRUD via `SqlDataAdapter` with embedded INSERT/UPDATE/DELETE/SELECT CommandText; SELECT `BillDetails.*` WHERE billId=@billId | YES |
| 16 | `MasterDbTdsDataSet.Designer.cs:3346-3628` | Typed DataSet TableAdapter for **BillHead** — full CRUD via `SqlDataAdapter`; SELECT `id,subCode,ayId,conscode,billNo,billDt,...` WHERE conscode=@conscode | YES |
| 17 | `MasterDbTdsDataSet.Designer.cs:3764-4076` | Typed DataSet TableAdapter for **BillReceipts** — full CRUD via `SqlDataAdapter`; SELECT `id,ayId,billId,receiptNo,...` WHERE billId=@billId | YES |

### Notes on `MasterDbTdsDataSet`

- **XSD location**: `SmartTdsWinUI\MasterDbTdsDataSet.xsd` (typed DataSet for the `MasterDbTds` database)
- **Tables bound**: `BillDetails`, `BillHead`, `BillReceipts` (3 tables; all in the `MasterDbTds` billing database)
- **Consumers** (WinForms forms that instantiate the TableAdapters):
  - `ConsultantBilling\FrmCreateBills.Designer.cs` — uses `BillDetailsTableAdapter` + `TableAdapterManager`
  - `ConsultantBilling\FrmBillDetails.Designer.cs` — uses `BillDetailsTableAdapter`
  - `ConsultantBilling\FrmReceipt.Designer.cs` — uses `BillReceiptsTableAdapter`
- **DevExpress reports**: `RptConsBill` and `RptConsBillNormal` receive a `List<BillDetails>` from the caller and set `DataSource = billDetLst` (no embedded SQL — data is pre-loaded by the form via BAL, then pushed into the report object). `RptForm138–RptForm144` all use BAL methods (`AddChallanBal`, `TdsEntryBal`, `PayeeBal`) and bind in-memory lists — no embedded SQL.
- **No `.repx` files** found in the WinUI tree (DevExpress reports are code-generated `XtraReport` subclasses only).

### Critical Migration Notes — Part A

1. **`FrmBackup.cs:BACKUP DATABASE`** (site 8) is a SQL Server–only command with no PostgreSQL equivalent. PostgreSQL backup requires `pg_dump` (run externally). The entire backup/restore UI must be redesigned.
2. **`FrmBackup.cs:sp_OACreate/sp_OAMethod`** (site 9) — SQL Server OLEDB Automation has no equivalent in PostgreSQL. File writing must move to application-side C# `File.AppendAllText`.
3. **`FrmBackup.cs:IF EXISTS ... UPDATE ... ELSE INSERT`** (site 12) — T-SQL `IF EXISTS` merge. PostgreSQL equivalent: `INSERT ... ON CONFLICT (name) DO UPDATE`.
4. **`Pump.cs:240` / `FrmUpdateDb.cs:87`** — `CREATE TABLE ApplicationParams(Id int IDENTITY(1,1) ...)` uses SQL Server identity syntax. PostgreSQL: `GENERATED ALWAYS AS IDENTITY` or `SERIAL`.
5. **`Common\DbScope.cs:149`** — queries `sys.databases` (SQL Server system catalogue). PostgreSQL equivalent: `pg_database` or `SELECT datname FROM pg_catalog.pg_database WHERE datname = $1`.
6. **`MasterDbTdsDataSet` TableAdapters** (sites 15–17) — auto-generated code using `System.Data.SqlClient`; uses `SCOPE_IDENTITY()` to retrieve inserted IDs. PostgreSQL equivalent: `RETURNING id` in the INSERT. The entire typed DataSet must be replaced (either Dapper, EF Core, or a manual PostgreSQL TableAdapter).

---

## Part B — Derived Schema & Type Mapping

### B.1 Entity → Table Mapping

#### MasterDbTds Database (MasterEntities namespace)

| C# Class | Table Name (inferred) | PK Column | Notes |
|----------|----------------------|-----------|-------|
| `ApplicationParams` | `ApplicationParams` | `Id` INT IDENTITY | Stores key/value config pairs (auth, ver, backupLoc, etc.) |
| `Assessee` | `Assessee` | `subCode` INT (not identity — assigned) | ~80 columns; large table; `profilePic byte[]` = varbinary/bytea |
| `AssesseeResStatus` | `AssesseeResStatus` | `id` INT IDENTITY | JSON blob in `resStatusVal` string |
| `AyMaster` | `AyMaster` | `id` INT IDENTITY | Many `DateTime` due-date columns |
| `BankDetails` | `BankDetails` | `id` INT IDENTITY | Soft-delete pattern (`IsDeleted` bit) |
| `BillDetails` | `BillDetails` | `id` INT IDENTITY | Confirmed by DataSet CommandText |
| `BillHead` | `BillHead` | `id` INT IDENTITY | Confirmed by DataSet CommandText |
| `Billmast` | `Billmast` | `billid` INT (identity assumed) | Legacy billing table; `receipt` bool/bit |
| `BillReceipts` | `BillReceipts` | `id` INT IDENTITY | Confirmed by DataSet CommandText |
| `CheckPeriod` | `CheckPeriod` | `id` INT IDENTITY | Quarter/month/ayid lookup |
| `Consultant` | `Consultant` | `consCode` INT (identity assumed) | Soft-delete; `flagDefault`/`flagPendingBillsNotifications` bools |
| `Country` | `Country` | `id` INT IDENTITY | Lookup table |
| `District` | `District` | `id` INT IDENTITY | Lookup table |
| `FeePaidMarking` | `FeePaidMarking` | `id` INT IDENTITY | `feePaid` bool/bit |
| `Group` | `Group` | `grpcode` INT (identity assumed) | Soft-delete |
| `Nature3` | `Nature3` | `code` INT (natural key) | Lookup; no surrogate PK |
| `Pincode` | `Pincode` | `id` INT IDENTITY | All code columns typed `double` in C# — likely stored as INT in DB |
| `PostOffice` | `PostOffice` | `id` INT IDENTITY | Lookup |
| `ReturnDates` | `ReturnDates` | `id` INT IDENTITY | `addressChangeOrg`, `addressChangeAuth`, `isRegularStatement`, `isNilReturn` are bools |
| `State` | `State` | `id` INT IDENTITY | Lookup |
| `SubDistrict` | `SubDistrict` | `id` INT IDENTITY | Lookup |
| `TdsEntriesSection` | `TdsEntriesSection` | `Paycode` INT (natural key) | No surrogate — Paycode is the key |
| `TdsNature` | `TdsNature` | `code` INT (natural key) | Lookup; no surrogate |
| `TdsRate` | `TdsRate` | composite (`ayid`,`tsId`,`PayCode`) | No single surrogate PK visible |
| `Tdsaomaster` | `Tdsaomaster` | `aocode` INT (natural key) | AO master lookup; ~40 columns |
| `Tdsded80` | `Tdsded80` | `ded80id` INT (identity assumed) | Section 80 deduction defs; many bool flags (bit → boolean) |
| `Tdsnscrate` | `Tdsnscrate` | `id` INT IDENTITY | NSC rate slabs |
| `Tdsnscrate2` | `Tdsnscrate2` | `id` INT IDENTITY | Extended NSC rate slabs |
| `User` | `User` | `userId` INT IDENTITY | Many bool flags; soft-delete |

#### SmartTds{YY} Databases (SmartTdsEntities namespace)

| C# Class | Table Name (inferred) | PK Column | Notes |
|----------|----------------------|-----------|-------|
| `AddChallan` | `AddChallan` | `id` INT IDENTITY; `chId` INT (business key per subCode/ayId) | `IsFromItdPortal` bool/bit; many `double` monetary fields |
| `Dateplace` | `Dateplace` | `dpId` INT IDENTITY | `revised`, `achange`, `achange2`, `nil` bools |
| `Ddodet` | `Ddodet` | `tid` INT IDENTITY | DDO detail; small table |
| `Depchild` | `Depchild` | `tid` INT IDENTITY | Dependent child certificate data; many `double` amounts |
| `FilingStatus` (in `Dof.cs`) | `FilingStatus` | `id` INT IDENTITY | 32 `string` columns for receipt nos / dates |
| `DualRegimeResult` | n/a — transient | — | Computed only; not persisted |
| `F15hn` | `F15hn` | `tid` INT IDENTITY | Form 15H/G header |
| `F15hnPayee` | `F15hnPayee` | `tid` INT IDENTITY | Form 15H/G payee-level data |
| `FilePending` | `FilePending` | `id` INT IDENTITY | `IsDeleted` bool; `ModifiedOn` DateTime |
| `Payee` | `Payee` | `id` INT IDENTITY | ~45 cols; `FreezePan` bool; `IsDeleted` bool; `ModifiedOn` DateTime |
| `Salary` | `Salary` | `id` INT IDENTITY | All monetary fields are `decimal` (not `double`) — maps to `numeric` |
| `SalaryNatureDetails` | `SalaryNatureDetails` | `id` INT IDENTITY | Sub-table of Salary |
| `SalaryExemptAllowances` | `SalaryExemptAllowances` | `id` INT IDENTITY | Sub-table of Salary |
| `SalaryPerquisiteDetails` | `SalaryPerquisiteDetails` | `id` INT IDENTITY | Sub-table of Salary |
| `TaxCalcResult` | n/a — transient | — | Computed only; not persisted |
| `Tds` | `Tds` | `id` INT IDENTITY | Sparse; may be a stub/header row |
| `Tdsallrule` | `Tdsallrule` | `id` INT IDENTITY | `step1`–`step7` string columns |
| `TdsCompIncome` | `TdsCompIncome` | `id` INT IDENTITY | ~60 `double` income/tax columns; `IsDeleted` bool |
| `TdsDeduction` | `TdsDeduction` | `id` INT IDENTITY | Deduction amounts; `senior`, `Ssenior`, `severe` bools |
| `TdsEntry` | `TdsEntry` | `id` INT IDENTITY | Core TDS entry; `eValid`, `IsDeleted` bools; dates stored as `string` |
| `TdsPayee` | `TdsPayee` | `id` INT IDENTITY | Challan-to-payee link view/table; amounts as `int` (unusual — see note) |
| `Tdsallrule` | `Tdsallrule` | `id` INT IDENTITY | Rule steps stored as strings |

---

### B.2 Consolidated SQL Server → PostgreSQL Type Mapping

| C# Type | Inferred SQL Server Type | PostgreSQL Target | Notes / Gotchas |
|---------|------------------------|-------------------|-----------------|
| `int` (identity PK) | `int IDENTITY(1,1)` | `integer GENERATED ALWAYS AS IDENTITY` | SQL Server uses `SCOPE_IDENTITY()` after INSERT; PG uses `RETURNING id`. All TableAdapters in MasterDbTdsDataSet.Designer.cs append `SELECT ... WHERE id = SCOPE_IDENTITY()` — must be rewritten as `INSERT ... RETURNING id`. |
| `int` (non-identity) | `int` | `integer` | Straightforward |
| `int?` (nullable int) | `int NULL` | `integer` (nullable by default in PG) | No change in DDL |
| `string` | `nvarchar(N)` / `nvarchar(MAX)` | `text` | SQL Server `nvarchar` = UTF-16; PG `text` = UTF-8. If strict length enforcement is needed use `varchar(N)`. Avoid PG `character varying` with no limit (same as `text` but less idiomatic). |
| `bool` | `bit` | `boolean` | SQL Server `bit` stores 0/1; PG `boolean` stores true/false. Parameterized queries using `bool` params work natively in Npgsql. |
| `DateTime` | `datetime` | `timestamp without time zone` | SQL Server `datetime` has 3.33ms precision; PG `timestamp` has 1µs precision — not an issue in practice. If timezone-aware storage is needed use `timestamptz`. |
| `DateTime?` | `datetime NULL` | `timestamp without time zone` (nullable) | |
| `double` (monetary) | `float` / `money` | `numeric(18,4)` or `double precision` | **CRITICAL**: The codebase uses `double` for monetary fields (TdsDeduct, Cess, GrndTotal, etc.). SQL Server `float` = IEEE-754 double. For TDS amounts, migrate to `numeric(18,4)` to avoid floating-point rounding in financial calculations. Existing data may need rounding on migration. |
| `decimal` (Salary.*) | `decimal(18,2)` / `money` | `numeric(18,4)` | Salary entity uses `decimal` — correct for financials. Map to PG `numeric`. |
| `byte[]` (Assessee.profilePic) | `varbinary(MAX)` / `image` | `bytea` | SQL Server `image` is deprecated; likely `varbinary(MAX)`. PG `bytea`. Npgsql handles this automatically. |
| `double` (Pincode code fields) | Likely `int` in DB (C# `double` is over-typed) | `integer` | Pincode.pinCode, .districtCode etc. are typed `double` in C# but represent integer codes. Verify actual column type in DB before migrating. |
| `int` (TdsPayee amounts) | Likely `int` / `bigint` | `integer` | `TdsPayee.AmtPay/TdsDeduct/Cess` are `int` — amounts in paise? Verify; most other entities use `double`. |
| `string` (date fields) | `varchar(10)` / `nvarchar(10)` | `text` or `date` | Dates stored as strings throughout (`DatePayment`, `DateDeduct`, `ChallanDt`, `dob`, `signingDate`). **Do NOT blindly convert to `date` columns** — format is `dd/MM/yyyy` in many places. Keep as `text` initially; convert column-by-column after format audit. |
| `bool` (`IsDeleted`) | `bit NOT NULL DEFAULT 0` | `boolean NOT NULL DEFAULT false` | Soft-delete pattern used across 15+ entities. |

---

### B.3 Columns Needing Manual Attention

| Column | Table | Issue |
|--------|-------|-------|
| `profilePic` | `Assessee` | `byte[]` — confirm current SQL Server type (`varbinary(MAX)` vs `image`) before migration |
| `pinCode`, `districtCode`, `stateCode`, `subDistrictCode`, `localityCode`, `postOfficeCode` | `Pincode` | Typed `double` in C# — almost certainly `int`/`bigint` in DB; fix C# type mapping on migration |
| All `DatePayment`, `DateDeduct`, `ChallanDt`, `dob`, `signingDate`, `date15g` etc. | Multiple | Stored as `string` in entity; actual DB column is `nvarchar(10)` holding `dd/MM/yyyy` strings. Migration choice: keep as `text` (safest) or convert to `date` after format-normalising all values. |
| `TdsPayee.AmtPay`, `.TdsDeduct`, `.Cess`, `.TotalTds2`, `.ActualTds` | `TdsPayee` | Typed `int` — inconsistent with `TdsEntry` where same fields are `double`. May be scaled (paise) or a legacy artifact. Verify SQL Server column type. |
| `Assessee.residentStatus`, `Assessee.assesseeStatus` | `Assessee` | 2-digit code strings (e.g. "01", "16"). Stored as `nvarchar(2)` — migrate as `text`. |
| `Assessee.auditCase`, `Assessee.IsDeleted`, `Assessee.dataFeeded` | `Assessee` | `bool` → SQL Server `bit NOT NULL` — confirm non-null constraint before migration |
| `Tdsded80.ind`, `.indnr`, `.huf`, `.hufnr`, `.firm`, `.company`, `.companynr`, `.coop` | `Tdsded80` | 8 separate `bool` columns representing applicability flags — consider if these could be consolidated, but keep as-is for safety in Phase 0 |
| `ReturnDates.nilSectionsCount` | `ReturnDates` | `int` — new column (added after initial release per comment `ReturnDates_AddBhFields.sql`); verify migration script includes it |
| `Salary.allwncExemptUs10`, all `Salary.decimal` fields | `Salary` | `decimal` in C# — verify SQL Server column is `decimal(18,4)` or `money`; map to PG `numeric(18,4)` |
| `ApplicationParams.value` | `ApplicationParams` | Altered at runtime to `nvarchar(MAX)` if truncated (Pump.cs:240). Ensure PG column is `text` (unlimited). |
| `MasterDbTdsDataSet` SCOPE_IDENTITY() | `BillDetails`, `BillHead`, `BillReceipts` | Auto-generated code appends `SELECT ... WHERE id = SCOPE_IDENTITY()` after each INSERT. Replace with `RETURNING id` clause in PG. The entire TableAdapter must be rewritten — cannot just swap the driver. |
| `FrmBackup` — BACKUP DATABASE command | Infrastructure | Not a column issue — entire backup subsystem must be replaced with pg_dump shell invocation or Npgsql-level backup API. |
| `sys.databases` probe (DbScope.cs:149) | Infrastructure | Replace with `SELECT COUNT(*) FROM pg_catalog.pg_database WHERE datname = $1` |
