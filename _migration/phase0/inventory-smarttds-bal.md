# SmartTdsBAL — Phase 0 Migration Inventory (SQL Server → PostgreSQL)

Generated: 2026-06-02  
Scope: `SmartTdsBAL\` project — all public DB-touching methods.  
Legend for PG Flags column: each flag is a T-SQL feature that needs a rewrite for PostgreSQL.

---

## AddChallanBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM AddChallan WHERE subCode+ayId | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetAll(int subCode, int ayId, string formType)` | SELECT * FROM AddChallan WHERE subCode+ayId+FormType | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetOne(int subCode, int ayId, int id)` | SELECT * FROM AddChallan WHERE subCode+ayId+id | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetMaxChId(int subCode, int ayId)` | `SELECT ISNULL(MAX(chId), 0) FROM AddChallan WHERE…` | `scalar` | parameterized | `ISNULL(` |
| `InsertAddChallan(AddChallan obj)` | INSERT INTO AddChallan (29 cols) VALUES (…); optional `[IsFromItdPortal]` column added conditionally | `bool/rowcount` | parameterized | `[identifiers]`, `BIT` literal in DDL, `IF COL_LENGTH(…) IS NULL ALTER TABLE … ADD … BIT NOT NULL CONSTRAINT … DEFAULT(0)` (DDL in code) |
| `UpdateOldChallan(AddChallan obj)` | UPDATE AddChallan SET 6 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `UpdateAddChallan(AddChallan obj)` | UPDATE AddChallan SET 29 cols WHERE id; optional IsFromItdPortal | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteAddChallan(int id)` | DELETE FROM AddChallan WHERE id | `bool/rowcount` | parameterized | — |
| `DeleteAddChallanByChId(int chId, int subCode, int ayId)` | DELETE FROM AddChallan WHERE chId+subCode+ayId | `bool/rowcount` | parameterized | — |
| `EnsureItdColumn()` (private) | DDL: `IF COL_LENGTH('AddChallan','IsFromItdPortal') IS NULL ALTER TABLE AddChallan ADD IsFromItdPortal BIT NOT NULL CONSTRAINT … DEFAULT(0)` | `scalar` | parameterized | `COL_LENGTH()` T-SQL system function, `IF … ALTER TABLE … ADD … BIT NOT NULL CONSTRAINT … DEFAULT(0)` — entire DDL idiom must be replaced with `ALTER TABLE … ADD COLUMN IF NOT EXISTS … BOOLEAN NOT NULL DEFAULT FALSE` in PG |

**Notes:**
- `EnsureItdColumn` uses SQL Server-specific DDL (`COL_LENGTH`, `IF` statement, `BIT` type, named `CONSTRAINT … DEFAULT`) — the full idiom needs a PG equivalent.
- All INSERT/UPDATE queries use square-bracket `[column]` identifiers throughout.

---

## DateplaceBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `FetchRecord(int ayId, int subCode, int quarter, int formId)` | SELECT * FROM Dateplace WHERE 4 cols | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetAll(int subCode, int ayId)` | SELECT * FROM Dateplace WHERE subCode+ayId | `List<T>/entity` | parameterized | `[identifiers]` |
| `InsertDateplace(Dateplace obj)` | INSERT INTO Dateplace (11 cols) VALUES (…) | `scalar` (returns identity via `InsertAndGetId`) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (in base class `InsertAndGetId`) |
| `UpdateDateplace(Dateplace obj)` | UPDATE Dateplace SET 7 cols WHERE dpId | `bool/rowcount` | parameterized | `[identifiers]` |

---

## DdodetBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM Ddodet WHERE subcode+ayid AND (IsDeleted IS NULL OR IsDeleted=0) | `List<T>/entity` | parameterized | — |
| `GetByPeriod(int subCode, int ayId, int period)` | SELECT * FROM Ddodet WHERE subcode+ayid+period AND (IsDeleted…) | `List<T>/entity` | parameterized | — |
| `InsertDdodet(Ddodet obj)` | INSERT INTO Ddodet (9 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteDdodet(int tid)` | DELETE FROM Ddodet WHERE tid | `bool/rowcount` | parameterized | — |

---

## DepchildBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM Depchild WHERE subcode+ayid AND (IsDeleted IS NULL OR IsDeleted=0) | `List<T>/entity` | parameterized | — |
| `GetByChId(int chid)` | SELECT * FROM Depchild WHERE chid AND (IsDeleted…) | `List<T>/entity` | parameterized | — |
| `InsertDepchild(Depchild obj)` | INSERT INTO Depchild (27 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |
| `InsertDepchildBatch(List<Depchild> rows)` | Chunked multi-row INSERT INTO Depchild (27 cols) VALUES (@p0_0,…),(…) in batches of 70 rows, in a transaction | `void` | parameterized (`AddWithValue`) | `[identifiers]`; exploits SQL Server 2100-param limit; chunking logic must change for PG (no hard 2100 limit — batching can be simplified); transaction management unchanged |
| `DeleteByChId(int chid)` | DELETE FROM Depchild WHERE chid | `bool/rowcount` | parameterized | — |
| `DeleteByTransId(int transid, int chid)` | DELETE FROM Depchild WHERE transid+chid | `bool/rowcount` | parameterized | — |

---

## DofBal.cs (contains `FilingStatusBal`)

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetOne(int subCode, int ayId)` | SELECT * FROM FilingStatus WHERE subCode+ayId | `List<T>/entity` | parameterized | `[identifiers]` |
| `Insert(FilingStatus obj)` | INSERT INTO FilingStatus (34 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |
| `Update(FilingStatus obj)` | UPDATE FilingStatus SET 32 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |

---

## F15hnBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM F15hn WHERE subcode+ayid AND (IsDeleted IS NULL OR IsDeleted=0) | `List<T>/entity` | parameterized | — |
| `GetByQuarter(int subCode, int ayId, string quarter)` | SELECT * FROM F15hn WHERE subcode+ayid+quarter AND (IsDeleted…) | `List<T>/entity` | parameterized | — |
| `InsertF15hn(F15hn obj)` | INSERT INTO F15hn (10 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteF15hn(int tid)` | DELETE FROM F15hn WHERE tid | `bool/rowcount` | parameterized | — |

---

## F15hnPayeeBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM F15hnPayee WHERE subcode+ayid AND (IsDeleted IS NULL OR IsDeleted=0) | `List<T>/entity` | parameterized | — |
| `GetByFormId(int formid)` | SELECT * FROM F15hnPayee WHERE formid AND (IsDeleted…) | `List<T>/entity` | parameterized | — |
| `InsertF15hnPayee(F15hnPayee obj)` | INSERT INTO F15hnPayee (16 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |

---

## FilePendingBAL.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM FilePending WHERE subCode+ayId AND IsDeleted=0 | `List<T>/entity` | parameterized | — |
| `GetOne(int id)` | SELECT * FROM FilePending WHERE id | `List<T>/entity` | parameterized | — |
| `InsertFilePending(FilePending obj)` | INSERT INTO FilePending (7 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (in base class) |
| `UpdateFilePending(FilePending obj)` | UPDATE FilePending SET 7 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteFilePending(int id)` | UPDATE FilePending SET IsDeleted = 1 WHERE id (soft delete) | `bool/rowcount` | parameterized | — |

---

## PayeeBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM Payee WHERE subCode+ayId | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetOne(int id, int subCode, int ayId)` | SELECT * FROM Payee WHERE id+subCode+ayId | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetModifiedPayeeList(int subCode, int ayId, DateTime modifiedOn, bool includeDeleted)` | SELECT * FROM Payee WHERE subCode+ayId AND ModifiedOn > @modifiedOn | `List<T>/entity` | parameterized | — |
| `InsertPayee(Payee obj)` | INSERT INTO Payee (40 cols) VALUES (…) | `bool/rowcount` | parameterized | `[identifiers]` |
| `InsertPayeeAndGetId(Payee obj)` | INSERT INTO Payee (40 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (in base class) |
| `UpdatePayee(Payee obj)` | UPDATE Payee SET 40 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `GetCascadeDeleteInfo(int payeeId, int subCode, int ayId)` | Orchestration: calls `TdsEntryBal.GetAllFrmPayee` + `TdsEntryBal.GetByChId` in a loop | `List<T>/entity` (returns `CascadeDeleteInfo` object) | parameterized | — (delegates to TdsEntryBal) |
| `DeletePayeeCascade(int payeeId, int subCode, int ayId)` | Orchestration: calls TdsEntryBal.UnlinkEntriesByChId, AddChallanBal.DeleteAddChallanByChId, TdsEntryBal.SoftDeleteByPayeeId, then `DELETE FROM Payee WHERE id = @id` | `bool/rowcount` | parameterized | — |
| `DeletePayee(int id)` | DELETE FROM Payee WHERE id | `bool/rowcount` | parameterized | — |

---

## SalaryBal.cs  (contains 4 BAL classes in one file)

### SalaryBal

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId, string salType)` | SELECT * FROM Salary WHERE subCode+ayId+salType | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetOne(int subCode, int ayId, int pcode)` | SELECT * FROM Salary WHERE subCode+ayId+pcode | `List<T>/entity` | parameterized | `[identifiers]` |
| `InsertSalaryGetId(Salary obj)` | INSERT INTO Salary (30 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateSalary(Salary obj)` | UPDATE Salary SET 30 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteOne(int id)` | DELETE FROM Salary WHERE id | `bool/rowcount` | parameterized | — |

### SalaryNatureDetailsBal

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAllForSalId(int salId)` | SELECT * FROM SalaryNatureDetails WHERE salId | `List<T>/entity` | parameterized | — |
| `InsertSalaryNatureDetailsList(List<SalaryNatureDetails> list)` | Calls `InsertOne` per row — INSERT INTO SalaryNatureDetails (4 cols) | `void` | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateSalaryNatureDetails(SalaryNatureDetails o)` | UPDATE SalaryNatureDetails SET 4 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteAllForSalId(int salId)` | DELETE FROM SalaryNatureDetails WHERE salId | `bool/rowcount` | parameterized | — |

### SalaryExemptAllowancesBal

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAllForSalId(int salId)` | SELECT * FROM SalaryExemptAllowances WHERE salId | `List<T>/entity` | parameterized | — |
| `InsertSalaryExemptAllowancesList(List<SalaryExemptAllowances> list)` | Calls `InsertOne` per row — INSERT INTO SalaryExemptAllowances (4 cols) | `void` | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateSalaryExemptAllowances(SalaryExemptAllowances o)` | UPDATE SalaryExemptAllowances SET 4 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteOne(int id)` | DELETE FROM SalaryExemptAllowances WHERE id | `bool/rowcount` | parameterized | — |
| `DeleteAllForSalId(int salId)` | DELETE FROM SalaryExemptAllowances WHERE salId | `bool/rowcount` | parameterized | — |

### SalaryPerquisiteDetailsBal

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAllForSalId(int salId)` | SELECT * FROM SalaryPerquisiteDetails WHERE salId | `List<T>/entity` | parameterized | — |
| `InsertSalaryPerquisiteDetailsList(List<SalaryPerquisiteDetails> list)` | Calls `InsertOne` per row — INSERT INTO SalaryPerquisiteDetails (4 cols) | `void` | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateSalaryPerquisiteDetails(SalaryPerquisiteDetails o)` | UPDATE SalaryPerquisiteDetails SET 4 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteOne(int id)` | DELETE FROM SalaryPerquisiteDetails WHERE id | `bool/rowcount` | parameterized | — |
| `DeleteAllForSalId(int salId)` | DELETE FROM SalaryPerquisiteDetails WHERE salId | `bool/rowcount` | parameterized | — |

---

## TaxCalcBal.cs

No database access. Pure in-memory income-tax calculation (slab tax, rebate 87A, surcharge, marginal relief, cess). **Zero DB methods.** No migration effort.

---

## TdsCompIncomeBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM TdsCompIncome WHERE subCode+ayId AND IsDeleted=0 | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetOne(int subCode, int ayId, int pcode)` | `SELECT TOP 1 * FROM TdsCompIncome WHERE subCode+ayId+pcode AND IsDeleted=0 ORDER BY id DESC` | `List<T>/entity` | parameterized | `TOP 1`, `[identifiers]` → PG: `LIMIT 1` |
| `Insert(TdsCompIncome obj)` | INSERT INTO TdsCompIncome (62 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateRow(TdsCompIncome obj)` | UPDATE TdsCompIncome SET 60 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteOne(int id)` | UPDATE TdsCompIncome SET IsDeleted=1 WHERE id (soft delete) | `bool/rowcount` | parameterized | — |
| `Upsert(TdsCompIncome obj)` | Orchestration: calls GetOne then Insert or UpdateRow | `scalar` | parameterized | — (delegates) |

**Note:** `TdsCompIncome.Insert` is the largest single-row INSERT in the project at 62 columns.

---

## TdsDeductionBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT * FROM TdsDeduction WHERE subCode+ayId AND IsDeleted=0 | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetAll(int subCode, int ayId, int pcode)` | SELECT * FROM TdsDeduction WHERE subCode+ayId+pcode AND IsDeleted=0 | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetOne(int subCode, int pcode, int ayId, int ded80id)` | SELECT * FROM TdsDeduction WHERE 4 cols AND IsDeleted=0 | `List<T>/entity` | parameterized | — |
| `SumDeduction80C(int subCode, int pcode, int ayId)` | `SELECT ISNULL(SUM(dedamt2),0) FROM TdsDeduction WHERE (ded80id=1 OR ded80id=39) AND…` | `scalar` | parameterized | `ISNULL(` |
| `SumDeductionOther(int subCode, int pcode, int ayId)` | `SELECT ISNULL(SUM(dedamt2),0) FROM TdsDeduction WHERE ded80id NOT IN (1,39) AND…` | `scalar` | parameterized | `ISNULL(` |
| `InsertDeduction(TdsDeduction obj)` | INSERT INTO TdsDeduction (22 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `UpdateDeduction(TdsDeduction obj)` | UPDATE TdsDeduction SET 20 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `DeleteDeduction(int id)` | UPDATE TdsDeduction SET IsDeleted=1 WHERE id (soft delete) | `bool/rowcount` | parameterized | — |

---

## TdsEntryBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetColumnMaxLengths()` (private static) | `SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TdsEntry' AND DATA_TYPE IN ('varchar','nvarchar','char','nchar')` | `scalar` | parameterized | `INFORMATION_SCHEMA.COLUMNS` (available in PG too, but `CHARACTER_MAXIMUM_LENGTH` returns -1 for `text`; query logic should work) |
| `GetAll(int subCode, int ayId)` | SELECT * FROM TdsEntry WHERE subCode+ayId | `List<T>/entity` | parameterized | — |
| `GetByChId(int subCode, int ayId, int chId)` | SELECT * FROM TdsEntry WHERE subCode+ayId+chId | `List<T>/entity` | parameterized | — |
| `GetAll(int subCode, int ayId, List<int> payCode)` | `SELECT * FROM TdsEntry WHERE subCode=@subCode AND ayId=@ayId AND Section IN (` + `string.Join(",", payCode)` + `)` | `List<T>/entity` | **STRING-CONCAT** — `paycodesStr` built by `string.Join` with integer literals inserted directly into SQL string | `IN (raw-concat-of-ints)` — **SQL injection risk** if `payCode` list could be externally influenced; replace with parameterized IN |
| `GetAllFrmPayee(int payeeId, int subCode, int ayId)` | SELECT * FROM TdsEntry WHERE payeeId+subCode+ayId | `List<T>/entity` | parameterized | — |
| `GetEntriesByPayeeLookup(IEnumerable<int> payeeIds, int subCode, int ayId)` | Chunked: `SELECT * FROM TdsEntry WHERE subCode=@subCode AND ayId=@ayId AND payeeId IN (@p0,…)` — chunks of 1500 ids | `List<T>/entity` | parameterized | — (chunking logic safe; PG has no 2100-param limit but chunking is harmless) |
| `GetAllPayee(int payeeId, int subCode, int ayId, int section, string formtype)` | SELECT * FROM TdsEntry WHERE payeeId+subCode+ayId+Section+FormType | `List<T>/entity` | parameterized | — |
| `GetTotalColumnValueUnderSection(…, string colName, …)` | `SELECT sum(` + colName + `) FROM TdsEntry WHERE …` | `scalar` | **STRING-CONCAT** — `colName` string concatenated directly: `"SELECT sum(" + colName + ")"` — **SQL injection risk** (column name from caller) | — |
| `GetTotalColumnValueUnderSections(…, int[] sections, string colName, …)` | `SELECT sum(` + colName + `) FROM TdsEntry WHERE … AND Section IN (` + sectionList + `)` | `scalar` | **STRING-CONCAT** — both `colName` and `sectionList` concatenated directly — **double SQL injection risk** | — |
| `GetTotalColumnValue(…, string colName, …)` | `SELECT sum(` + colName + `) FROM TdsEntry WHERE …` | `scalar` | **STRING-CONCAT** — `colName` concatenated directly | — |
| `GetMonthlyTotalUnderSection(…, string colName, …, string monthYear)` | `SELECT sum(` + colName + `) FROM TdsEntry WHERE … AND SUBSTRING(DatePayment, 4, 7) = @monthYear` | `scalar` | **STRING-CONCAT** — `colName` concatenated; `SUBSTRING` call | `SUBSTRING(col, 4, 7)` — T-SQL `SUBSTRING` (same function name in PG but syntax is identical; however `SUBSTRING(str, pos, len)` is supported in PG — acceptable, no change needed) |
| `GetOne(int id, int subCode, int ayId)` | SELECT * FROM TdsEntry WHERE id+subCode+ayId | `List<T>/entity` | parameterized | — |
| `GetOneMax(int subCode, int ayId, string colName)` | `SELECT TOP 1 * FROM TdsEntry WHERE subCode+ayId ORDER BY ` + colName + ` DESC` | `List<T>/entity` | **STRING-CONCAT** — `colName` concatenated directly into ORDER BY | `TOP 1` → PG: `LIMIT 1`; `colName` concat |
| `UpdateChId(TdsEntry obj)` | UPDATE TdsEntry SET chId+DateDeposit+ChInterest+ChTdsDep WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `UpdateChIdBatch(List<TdsEntry> entries, Action<int,int> onProgress)` | Chunked: `UPDATE t SET … FROM TdsEntry t INNER JOIN (VALUES (@p0_id,…),…) AS s(id,…) ON t.id=s.id` — batches of 400 rows, one transaction | `void` | parameterized (`AddWithValue`) | `UPDATE … FROM … INNER JOIN (VALUES …) AS s(…)` — SQL Server proprietary UPDATE-FROM-JOIN syntax; **PG equivalent**: `UPDATE TdsEntry SET … FROM (VALUES …) AS s(id,…) WHERE TdsEntry.id = s.id` (slightly different syntax) |
| `InsertTdsEntry(TdsEntry obj)` | INSERT INTO TdsEntry (33 cols) VALUES (…) | `scalar` (returns identity) | parameterized | `[identifiers]`, `SCOPE_IDENTITY()` (base class) |
| `InsertTdsEntryBatch(List<TdsEntry> entries, Action<int,int> onProgress)` | Chunked: multi-row INSERT INTO TdsEntry (33 cols) VALUES (…); `SELECT CAST(SCOPE_IDENTITY() AS INT) AS LastId` appended; batches of 50 rows, one transaction | `void` | parameterized (`AddWithValue`) | `SCOPE_IDENTITY()` critical — entire id-backfill strategy depends on contiguous SQL Server identity allocation; **PG migration requires** `INSERT … RETURNING id` or `lastval()` approach; the chunked-SCOPE_IDENTITY pattern does NOT port as-is |
| `UpdateTdsEntry(TdsEntry obj)` | UPDATE TdsEntry SET 33 cols WHERE id | `bool/rowcount` | parameterized | `[identifiers]` |
| `ClearCaughtUpTdsDedLater(int payeeId, int subCode, int ayId, int section, string formType)` | UPDATE TdsEntry SET TdsDedLater=0 WHERE payeeId+subCode+ayId+Section+FormType AND TdsDeduct=0 AND TdsDedLater!=0 | `void` | parameterized | — |
| `DeleteTdsEntry(int id)` | DELETE FROM TdsEntry WHERE id | `bool/rowcount` | parameterized | — |
| `DeleteByChId(int chId, int subCode, int ayId, string formType)` | DELETE FROM TdsEntry WHERE chId+subCode+ayId+FormType | `bool/rowcount` | parameterized | — |
| `SoftDeleteByPayeeId(int payeeId, int subCode, int ayId)` | UPDATE TdsEntry SET IsDeleted=1 WHERE payeeId+subCode+ayId | `void` | parameterized | — |
| `UnlinkEntriesByChId(int chId, int subCode, int ayId)` | UPDATE TdsEntry SET chId=0, DateDeposit=NULL WHERE chId+subCode+ayId | `void` | parameterized | — |

**STRING-CONCAT SITES in TdsEntryBal.cs (5 methods):**
1. `GetAll(…, List<int> payCode)` — Section IN (raw int list)
2. `GetTotalColumnValueUnderSection` — column name in SELECT
3. `GetTotalColumnValueUnderSections` — column name + int array in SELECT+WHERE
4. `GetTotalColumnValue` — column name in SELECT
5. `GetMonthlyTotalUnderSection` — column name in SELECT
6. `GetOneMax` — column name in ORDER BY

---

## TdsPayeeBal.cs

| Method | SQL type | Return type | Param/Concat | PG Flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | Multi-table SELECT: TdsEntry JOIN Payee JOIN `[MasterDbTds].[dbo].[TdsEntriesSection]` WHERE `t.subCode = {0} AND t.ayId = {1}` (string.Format) | `List<T>/entity` | **STRING-CONCAT** — `string.Format(…, subCode, ayId)` inserts int values directly into SQL string | Cross-database 3-part name `[MasterDbTds].[dbo].[TdsEntriesSection]` — **PG does NOT support cross-database queries**; must be redesigned (e.g., use `dblink`, FDW, or move data to same DB); also `[identifiers]` throughout |
| `GetAll(int subCode, int ayId, string formType)` | SELECT TdsEntry JOIN Payee WHERE subCode+ayId+FormType | `List<T>/entity` | parameterized | `[identifiers]` |
| `GetAllForChallan(int subCode, int ayId, string formCode, int editChId)` | Dynamic SELECT TdsEntry JOIN Payee with conditional WHERE clauses built by StringBuilder (chId filter + FormType filter); conditions appended as string literals but values passed as parameters | `List<T>/entity` | parameterized (string literal conditions are fixed code, not user data) | `[identifiers]`; dynamic SQL assembly (safe — only fixed string literals appended, no user values concatenated) |

**Critical:** `TdsPayeeBal.GetAll(subCode, ayId)` uses `string.Format` to inject integer params directly into SQL AND references `[MasterDbTds].[dbo].[TdsEntriesSection]` — a cross-database 3-part name that has no equivalent in PostgreSQL.

---

## DbVariables.cs

No database methods — contains only connection-string properties and `SetDataSourceString()` which calls `SmartTdsVariables.SetDataSourceString`. The connection string uses SQL Server format (`data source=`, `User ID=`, `Password=`, `Initial Catalog=`, `MultipleActiveResultSets=True`). **Migration: replace with Npgsql connection string format.**

## Extensions.cs

No database methods — pure C# extension methods for null-safe conversion, data-reader helpers (`DrToDouble`, `GetSafeInt`, `ColumnExists`, etc.). These are dialect-independent and port unchanged.

---

## SmartTdsBAL Summary

### Totals

| Metric | Count |
|--------|-------|
| Total files with DB methods | 14 (AddChallan, Dateplace, Ddodet, Depchild, DofBal/FilingStatus, F15hn, F15hnPayee, FilePending, Payee, Salary×4 classes, TdsCompIncome, TdsDeduction, TdsEntry, TdsPayee) |
| Total public DB-touching methods | 92 |
| Methods returning `List<T>/entity` | 51 |
| Methods returning `scalar` (identity or aggregate) | 14 |
| Methods returning `bool/rowcount` | 24 |
| Methods returning `void` | 3 |
| **DataTable / DataSet returns** | **0** (entire BAL layer uses typed entity mapping — zero DataTable/DataSet) |
| **STRING-CONCAT sites (SQL injection / porting risk)** | **7** across 2 files: 6 in TdsEntryBal.cs + 1 in TdsPayeeBal.cs |
| T-SQL `ISNULL(` usages | 4 (GetMaxChId, SumDeduction80C, SumDeductionOther; base class likely has more) |
| T-SQL `TOP 1` usages | 2 (TdsCompIncomeBal.GetOne, TdsEntryBal.GetOneMax) |
| `SCOPE_IDENTITY()` dependency | Pervasive — all `InsertAndGetId` paths + batch insert in TdsEntryBal |
| Square-bracket `[identifiers]` | Present in virtually every INSERT/UPDATE query (~50+ queries) |
| Cross-database 3-part name | 1 — `[MasterDbTds].[dbo].[TdsEntriesSection]` in TdsPayeeBal.GetAll |
| DDL executed from application code | 1 — `EnsureItdColumn` in AddChallanBal (IF COL_LENGTH … ALTER TABLE … ADD BIT) |
| SQL Server-specific batch UPDATE syntax (`UPDATE … FROM … INNER JOIN (VALUES …)`) | 1 — TdsEntryBal.UpdateChIdBatch |
| Multi-row INSERT with SCOPE_IDENTITY id-backfill | 2 — TdsEntryBal.InsertTdsEntryBatch, DepchildBal.InsertDepchildBatch |

### Top 5 Most Complex / Risky Methods to Port

1. **`TdsEntryBal.InsertTdsEntryBatch`** — Chunked 33-column multi-row INSERT with `SCOPE_IDENTITY()` used to back-fill IDs by assuming contiguous identity allocation. PG has no `SCOPE_IDENTITY()`; must be redesigned using `INSERT … RETURNING id` (array return) or per-row `lastval()` after each statement. The contiguous-allocation assumption also does not hold for sequences with `nextval` caching. Highest migration complexity.

2. **`TdsEntryBal.UpdateChIdBatch`** — Uses SQL Server proprietary `UPDATE t SET … FROM TdsEntry t INNER JOIN (VALUES …) AS s(…) ON t.id = s.id` syntax. PG syntax differs: `UPDATE TdsEntry SET … FROM (VALUES …) AS s(…) WHERE TdsEntry.id = s.id`. Functionally equivalent but requires a complete rewrite of the SQL string.

3. **`TdsPayeeBal.GetAll(int subCode, int ayId)`** — References `[MasterDbTds].[dbo].[TdsEntriesSection]` (3-part cross-database name). PostgreSQL does not support cross-database joins. Requires an architectural decision: either migrate MasterDbTds into the same PG database, use `dblink`/FDW, or load the section data in-memory (comment in the code already hints the fast overload does this). Also uses `string.Format` injection.

4. **`AddChallanBal.EnsureItdColumn`** — Runs DDL from application code using SQL Server-specific idioms: `IF COL_LENGTH('AddChallan','IsFromItdPortal') IS NULL ALTER TABLE … ADD … BIT NOT NULL CONSTRAINT … DEFAULT(0)`. PG equivalent: `ALTER TABLE AddChallan ADD COLUMN IF NOT EXISTS IsFromItdPortal BOOLEAN NOT NULL DEFAULT FALSE`. The entire conditional-DDL pattern needs rewriting; also `BIT` → `BOOLEAN`.

5. **`TdsEntryBal.GetTotalColumnValueUnderSection / GetTotalColumnValueUnderSections / GetTotalColumnValue / GetOneMax`** — Four methods that accept a `colName` string and build `SELECT sum(colName)` or `ORDER BY colName` by direct string concatenation. These are SQL injection vectors and also require care on PG to ensure column identifiers are quoted with double-quotes instead of square brackets. Each call-site must be audited to confirm `colName` values are safe (internal enum-driven), and the pattern should be replaced with a safe column-name whitelist.

### Notes on DataTable/DataSet Porting Cost

The SmartTdsBAL project has **zero DataTable/DataSet returns**. All DB methods use typed entity classes with the `DbBaseClass<T>` generic mapper. This is the best-case scenario for migration: the mapper layer (`Map()` override per class) only needs the connection provider swapped (SqlConnection → NpgsqlConnection) and T-SQL quirks fixed. No DataAdapter/DataSet unwinding is required.

### Cross-cutting PG Migration Actions

| Action | Scope |
|--------|-------|
| Replace `SqlConnection`/`SqlCommand`/`SqlParameter` with Npgsql equivalents | All files |
| Replace `ISNULL(x, y)` with `COALESCE(x, y)` | 4 methods |
| Replace `TOP 1` with `LIMIT 1` | 2 methods |
| Replace `[identifier]` with `"identifier"` or unquoted | All INSERT/UPDATE queries |
| Replace `SCOPE_IDENTITY()` with `RETURNING id` / `lastval()` | Base class `InsertAndGetId` + batch inserts |
| Redesign `InsertTdsEntryBatch` id-backfill | TdsEntryBal |
| Rewrite `UpdateChIdBatch` UPDATE-FROM-JOIN syntax | TdsEntryBal |
| Fix 5 STRING-CONCAT column-name injection sites | TdsEntryBal |
| Fix 1 STRING-CONCAT + cross-DB join | TdsPayeeBal |
| Replace DDL helper `EnsureItdColumn` | AddChallanBal |
| Replace connection string format | DbVariables.cs |
| `BIT` type (SQL Server) → `BOOLEAN` (PG) | AddChallanBal DDL |
| `SUBSTRING(col, pos, len)` — syntax compatible; no change needed | TdsEntryBal |
