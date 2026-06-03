# MasterBal Migration Inventory — Phase 0
**Scope:** MasterBal project only  
**Target:** SQL Server → PostgreSQL  
**Date:** 2026-06-02  

Legend — PG flags key:  
`ISNULL` `GETDATE` `LEN` `CHARINDEX` `+concat` `IDENTITY/SCOPE_IDENTITY` `[brackets]` `CONVERT` `DATEPART` `bit-literal` `NOLOCK` `TOP` `#temp` `MERGE` `sys-catalog`  

---

## DbVariables.cs

No SQL. Contains connection-string builder only.  
**PG note:** `DataSourceString` is hard-coded in SQL Server format (`data source=...;Initial Catalog=...`). Must be replaced with Npgsql DSN (`Host=...;Database=...`) at migration time.

---

## MasterBalExtensions.cs

No SQL. Pure C# extension/helper methods. No DB portability flags.

---

## ApplicationParamsBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetOne(string name)` | SELECT `* from ApplicationParams where name=@name` | `List<T>/entity` (SelectSingle → ApplicationParams) | parameterized | `[brackets]` in UPDATE only |
| `UpdateApplicationParams(string name, string val)` | UPDATE `ApplicationParams SET value=@value WHERE [name]=@name` | `bool/rowcount` | parameterized | `[brackets]` |

---

## AssesseeBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllAssessees(string prodKey, bool includeDeleted=false)` | SELECT `* from Assessee where (IsDeleted IS NULL OR IsDeleted=0) and prodKey=@prodKey` | `List<T>/entity` | parameterized | — |
| `GetModifiedAssesseeList(string prodKey, DateTime modifiedOn, bool includeDeleted=false)` | SELECT `* from Assessee where … prodKey=@prodKey and ModifiedOn>@modifiedOn` | `List<T>/entity` | parameterized | — |
| `GetOneAssessee(int subCode, string prodKey)` | SELECT `* from Assessee where subCode=@subCode and prodKey=@prodKey` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertAssessee(Assessee obj)` | INSERT 115-column INSERT INTO Assessee | `scalar` (InsertAndGetId → int) | parameterized | `[brackets]` throughout; relies on `IDENTITY`/`SCOPE_IDENTITY()` via base `InsertAndGetId` |
| `UpdateAssessee(Assessee obj)` | UPDATE 115-column UPDATE Assessee … WHERE [subCode]=@subCode | `bool/rowcount` | parameterized | `[brackets]` throughout |
| `UpdatePassword(int subcode, string username, string pwd)` | UPDATE `Assessee SET [userId]=@username,[password]=@pwd,[ModifiedOn]=@modifiedOn WHERE [subCode]=@subcode` | `bool/rowcount` | parameterized | `[brackets]` |
| `UpdatePRANNum(int subcode, string PRANNum)` | UPDATE `Assessee SET [PRANNum]=@PRANNum,[ModifiedOn]=@modifiedOn WHERE [subCode]=@subcode` | `bool/rowcount` | parameterized | `[brackets]` |
| `UpdateFatherName(int subcode, string fatherName)` | UPDATE `Assessee SET [fatherName]=@fatherName,[ModifiedOn]=@modifiedOn WHERE [subCode]=@subcode` | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteAssessee(int subcode)` | UPDATE `Assessee set IsDeleted=@IsDeleted,[ModifiedOn]=@modifiedOn where subCode=@subCode` (soft-delete) | `bool/rowcount` | parameterized | — |
| `GetDeletedAssessees(string prodKey)` | SELECT `* FROM Assessee WHERE IsDeleted=1 AND prodKey=@prodKey` | `List<T>/entity` | parameterized | — |
| `RestoreAssessee(int subcode)` | UPDATE `Assessee SET IsDeleted=0,[ModifiedOn]=@modifiedOn WHERE subCode=@subcode` | `bool/rowcount` | parameterized | — |
| `GetAssesseeColumnMaxLengths()` (private static) | SELECT `COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Assessee'` | `scalar` (dict build) | parameterized | `INFORMATION_SCHEMA` (also in PG, but column/table naming differs slightly) |

**Notes:**  
- `InsertAssessee` and `UpdateAssessee` are the two most complex methods in the entire project: 115 parameters each, including a `profilePic` binary (byte[]) column.  
- `bool` columns (`auditCase`, `IsDeleted`, `dscLinkedFlag`) are mapped as C# `bool` — in SQL Server these are `bit`; PG uses `boolean`. The `bool` wire mapping is handled by the driver but the `bit` schema definition changes.  
- `IsDeleted=0/1` literals appear in several SELECT WHERE clauses — PG boolean literals are `false/true` or `0/1` only in integer context; use `false` for clarity.

---

## AssesseeResStatusBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllAssesseeResStatuss(int ayId)` | SELECT `* from AssesseeResStatus where ayId=@ayId` | `List<T>/entity` | parameterized | — |
| `GetModifiedAssesseeResStatusList(int ayId, DateTime modifiedOn)` | SELECT `* from AssesseeResStatus where ayId=@ayId and ModifiedOn>@modifiedOn` | `List<T>/entity` | parameterized | — |
| `GetOneAssesseeResStatus(int subCode, int ayId)` | SELECT `* from AssesseeResStatus where subCode=@subCode and ayId=@ayId` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertAssesseeResStatus(AssesseeResStatus obj)` | INSERT INTO AssesseeResStatus (5 columns) | `scalar` (InsertAndGetId → int) | parameterized | `IDENTITY` via base |
| `UpdateAssesseeResStatus(AssesseeResStatus obj)` | UPDATE AssesseeResStatus 5 cols WHERE id=@id | `bool/rowcount` | parameterized | — |

---

## AyMasterBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllAy()` | SELECT `* from AyMaster` (bare string, no SqlCommand) | `List<T>/entity` | parameterized (no user input) | — |
| `UpdateDateExtensions(AyMaster obj)` | UPDATE `AyMaster SET [NonBusInc]=@NonBusInc … WHERE [id]=@id` (14 date columns) | `bool/rowcount` | parameterized | `[brackets]`; dates passed as `dd/MM/yyyy` strings (not typed DateTime) — **PG date parsing is stricter** |

---

## BankDetailsBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllBankDetails(int subCode, bool deleted=false)` | SELECT `* FROM BankDetails WHERE subCode=@subCode AND IsDeleted=@deleted` | `List<T>/entity` | parameterized | — |
| `GetOneBankDetail(string id)` | SELECT `* from BankDetails where id=@id` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertBankDetails(BankDetails obj)` | INSERT INTO BankDetails (16 cols) | `bool/rowcount` | parameterized | `[brackets]` |
| `UpdateBankDetails(BankDetails obj)` | UPDATE BankDetails 16 cols WHERE id=@id | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteBankDetails(int id)` | UPDATE `BankDetails set IsDeleted=@IsDeleted where id=@id` (soft-delete) | `bool/rowcount` | parameterized | — |
| `DeleteAllBankDetails(int subcode)` | UPDATE `BankDetails set IsDeleted=@IsDeleted where subcode=@subcode` | `bool/rowcount` | parameterized | — |

---

## BillDetailsBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `InsertBillDetails(BillDetails obj)` | INSERT INTO BillDetails (14 cols) | `bool/rowcount` | parameterized | `[brackets]` |
| `UpdateBill(BillDetails obj)` | UPDATE BillDetails 14 cols WHERE id=@id | `bool/rowcount` | parameterized | `[brackets]` |
| `GetAllBillDetails(int billId)` | SELECT `* FROM BillDetails WHERE billId=@billId` | `List<T>/entity` | parameterized | — |
| `DeleteBill(int id, bool delete)` | DELETE `from BillDetails WHERE [id]=@id` | `bool/rowcount` | parameterized | `[brackets]` |

---

## BillHeadBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllUndeletedBills(int conscode, int ayId, int subCode=0)` | SELECT `* FROM BillHead WHERE ayId=@ayId AND conscode=@conscode AND (IsDeleted IS NULL OR IsDeleted=0) [AND subCode=@subCode]` | `List<T>/entity` | parameterized | — |
| `GetAllBills(int conscode, int ayId, int subCode=0)` | SELECT `* FROM BillHead WHERE … ORDER BY billNo DESC` | `List<T>/entity` | parameterized | — |
| `GetAllPendingBills(int subCode)` | SELECT `* FROM BillHead WHERE subCode=@subCode AND (totAmt-amtReceived-amtDisc)>0 AND (IsDeleted IS NULL OR IsDeleted=0)` | `List<T>/entity` | parameterized | — |
| `GetOneBill(int id)` | SELECT `* from BillHead where id=@id` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetPrevBill(int conscode, int ayId, int billNo)` | SELECT `* FROM BillHead WHERE … billNo<@billNo ORDER BY billNo DESC` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetNextBill(int conscode, int ayId, int billNo)` | SELECT `* FROM BillHead WHERE … billNo>@billNo ORDER BY billNo` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetNextBillNo(int conscode, int ayId)` | SELECT `ISNULL(Max(BillNo),0)+1 FROM BillHead WHERE …` | `scalar` (string via ToOneColumn) | parameterized | **`ISNULL(`** → PG `COALESCE` |
| `GetLastBill(int conscode, int ayId)` | SELECT `* FROM BillHead WHERE … billNo=(SELECT Max(billNo) FROM BillHead WHERE …)` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetBillByNo(int conscode, int ayId, int billNo)` | SELECT `* FROM BillHead WHERE … billNo=@billNo` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertBillAndGetId(BillHead obj)` | INSERT INTO BillHead (15 cols) with embedded sub-SELECT `ISNULL(Max(BillNo),0)+1` for auto-bill-number | `scalar` (InsertAndGetId → int) | parameterized | **`ISNULL(`** in sub-SELECT; `[brackets]`; `IDENTITY` via base |
| `UpdateBill(BillHead obj)` | UPDATE BillHead 15 cols WHERE id=@id | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteBill(int id, bool delete)` | UPDATE `BillHead SET [IsDeleted]=@IsDeleted WHERE [id]=@id` | `bool/rowcount` | parameterized | `[brackets]` |

---

## BillReceiptsBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetLastBillReceiptNo(string dateFrm, string dateTo)` | SELECT `max(receiptNo) FROM BillReceipts WHERE CONVERT(datetime,receiptDt)>=CONVERT(datetime,@dateFrm) AND CONVERT(datetime,receiptDt)<=CONVERT(datetime,@dateTo)` | `scalar` (string via ToOneColumn) | parameterized | **`CONVERT(datetime,…)`** × 4 → PG `::timestamp` or `CAST(… AS timestamp)` |
| `GetOneBillReceipt(int id)` | SELECT `* from BillReceipts where id=@id` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertBillReceipt(BillReceipts obj)` | INSERT INTO BillReceipts (14 cols) | `bool/rowcount` | parameterized | `[brackets]` |
| `UpdateBillReceipt(BillReceipts obj)` | UPDATE BillReceipts 14 cols WHERE id=@id | `bool/rowcount` | parameterized | `[brackets]` |

---

## BillmastBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int ayId)` | SELECT `* FROM Billmast WHERE ayid=@ayId AND (IsDeleted IS NULL OR IsDeleted=0)` | `List<T>/entity` | parameterized | — |
| `GetBySubcode(int subcode)` | SELECT `* FROM Billmast WHERE subcode=@subcode AND (IsDeleted IS NULL OR IsDeleted=0)` | `List<T>/entity` | parameterized | — |
| `InsertBillmast(Billmast obj)` | INSERT INTO Billmast (33 cols) | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteBillmast(int billid)` | DELETE `FROM Billmast WHERE billid=@billid` | `bool/rowcount` | parameterized | — |

---

## CheckPeriodBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from Check_period` | `List<T>/entity` | parameterized (no user input) | — |
| `GetByQuarter(int quarter, int ayid)` | SELECT `* FROM Check_period WHERE quarter=@quarter AND ayid=@ayid` | `List<T>/entity` | parameterized | — |

---

## ConsultantBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllConsultants(string prodKey, bool includeDeleted=false)` | SELECT `* FROM Consultant WHERE prodKey=@prodKey [AND (IsDeleted IS NULL OR IsDeleted=0)]` | `List<T>/entity` | parameterized | — |
| `GetOneConsultant(int consCode, string prodKey)` | SELECT `* from Consultant where consCode=@consCode and prodKey=@prodKey` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertConsultant(Consultant obj)` | INSERT INTO Consultant (37 cols including `logo` blob) | `scalar` (InsertAndGetId → int) | parameterized | `[brackets]`; `IDENTITY` via base |
| `InsertConsultantBulk(List<Consultant> lst)` | Bulk INSERT via `SqlBulkCopy` (InsertBulk / AsDataTable) | `void` | parameterized | **SqlBulkCopy has no direct PG equivalent** — use `COPY FROM` or batched Npgsql inserts |
| `UpdateConsultant(Consultant obj)` | UPDATE Consultant 37 cols WHERE consCode=@consCode | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteConsultant(int consCode)` | UPDATE `Consultant set IsDeleted=@IsDeleted where consCode=@consCode` (soft-delete) | `bool/rowcount` | parameterized | — |

---

## CountryBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllCountry()` | SELECT `* from Country` | `List<T>/entity` | parameterized (no user input) | — |

---

## DistrictBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllDistricts()` | SELECT `* from District order by name` | `List<T>/entity` | parameterized (no user input) | — |

---

## FeePaidMarkingBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllList(int fyid)` | SELECT `* FROM FeePaidMarking WHERE fyid=@fyid` | `List<T>/entity` | parameterized | — |
| `GetAllList(int fyid, int periodId)` | SELECT `* FROM FeePaidMarking WHERE fyid=@fyid AND periodId=@periodId` | `List<T>/entity` | parameterized | — |
| `GetOne(int id)` | SELECT `* FROM FeePaidMarking WHERE id=@id` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertFeePaidMarking(FeePaidMarking obj)` | INSERT INTO FeePaidMarking (7 cols) | `scalar` (InsertAndGetId → int) | parameterized | `IDENTITY` via base |
| `UpdateFeePaidMarking(FeePaidMarking obj)` | UPDATE FeePaidMarking 3 cols WHERE id=@id | `bool/rowcount` | parameterized | — |

---

## GroupBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllUndeletedGroups(string prodkey)` | SELECT `* FROM Groups WHERE (IsDeleted IS NULL OR IsDeleted=0) AND prodKey=@prodKey` | `List<T>/entity` | parameterized | — |
| `GetOneGroup(int id, string prodkey)` | SELECT `* from Groups where grpcode=@grpcode and prodKey=@prodKey` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `InsertGroup(Group group)` | INSERT INTO Groups (9 cols) | `bool/rowcount` | parameterized | `[brackets]`; C# string concat for SQL text only (not user data) |
| `InsertGroupsBulk(List<Group> groups)` | Bulk INSERT via SqlBulkCopy | `void` | parameterized | **SqlBulkCopy** → PG `COPY` |
| `DeleteGroup(int id)` | UPDATE `Groups set IsDeleted=@IsDeleted where grpcode=@grpcode` (soft-delete) | `bool/rowcount` | parameterized | — |
| `UpdateGroup(Group group)` | UPDATE Groups 8 cols WHERE grpcode=@grpcode | `bool/rowcount` | parameterized | — |

---

## Nature3Bal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from Nature3` | `List<T>/entity` | parameterized (no user input) | — |
| `GetByCode(int code)` | SELECT `* FROM Nature3 WHERE code=@code` | `List<T>/entity` (FirstOrDefault) | parameterized | — |

---

## PincodeBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllPincodes()` | SELECT `* from Pincode` | `List<T>/entity` | parameterized (no user input) | — |
| `GetOnePincode(string pincode)` | SELECT `* FROM Pincode WHERE pinCode=@pincode` | `List<T>/entity` | parameterized | — |

---

## PostOfficeBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllPostOffices()` | SELECT `* from PostOffice order by name` | `List<T>/entity` | parameterized (no user input) | — |

---

## ReturnDatesBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll(int subCode, int ayId)` | SELECT `* FROM ReturnDates WHERE subcode=@subcode AND ayid=@ayid` | `List<T>/entity` | parameterized | — |
| `GetOne(int subCode, int ayId, string quarter)` | SELECT `* FROM ReturnDates WHERE subcode=@subcode AND ayid=@ayid AND quarter=@quarter` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetOne(int subCode, int ayId, string quarter, string formName)` | SELECT with 4-part natural key | `List<T>/entity` (SelectSingle) | parameterized | — |
| `Save(ReturnDates obj)` | SELECT then INSERT or UPDATE (upsert logic in C#, catches SQL error 2627/2601) | `bool/rowcount` | parameterized | Error codes 2627/2601 are SQL Server-specific; PG equivalent is `23505` (unique_violation); **must update catch logic** |
| `InsertReturnDates(ReturnDates obj)` | INSERT INTO ReturnDates (13 cols) | `bool/rowcount` | parameterized | — |
| `UpdateReturnDates(ReturnDates obj)` | UPDATE ReturnDates 13 cols WHERE id=@id | `bool/rowcount` | parameterized | — |
| `DeleteReturnDates(int id)` | DELETE `FROM ReturnDates WHERE id=@id` | `bool/rowcount` | parameterized | — |
| `GetColumnMaxLengths()` (private static) | SELECT `COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='ReturnDates'` | `scalar` (dict build) | parameterized | `INFORMATION_SCHEMA` (PG-compatible with minor casing differences) |

**Critical PG note:** `Save()` catches `SqlException` checking `ex.Number == 2627 || ex.Number == 2601`. In PG (Npgsql), use `NpgsqlException` with `SqlState == "23505"`. This code requires a targeted fix or replace with a native PG `INSERT … ON CONFLICT DO UPDATE`.

---

## StateBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllStates()` | SELECT `* from State order by name` | `List<T>/entity` | parameterized (no user input) | — |

---

## SubDistrictBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllSubDistricts()` | SELECT `* from SubDistrict order by name` | `List<T>/entity` | parameterized (no user input) | — |

---

## TdsEntriesSectionBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from TdsEntriesSection` | `List<T>/entity` | parameterized (no user input) | — |
| `GetByPayCode(List<int> paycodes, string formName)` | SELECT `* FROM TdsEntriesSection WHERE Paycode IN (` **+ paycodesStr +** `) AND FormName=@formName` | `List<T>/entity` | **STRING-CONCAT** ⚠️ — integer list inlined: `string.Join(",", paycodes)` | `+` string concat for IN list |
| `GetOne(int Paycode)` | SELECT `* FROM TdsEntriesSection WHERE Paycode=@Paycode` | `List<T>/entity` (SelectSingle) | parameterized | — |

**Injection risk note:** `GetByPayCode` builds `WHERE Paycode IN (1,2,3)` by joining integers. Values are integers (not strings) so actual SQL injection is impossible, but the pattern is flagged as STRING-CONCAT by policy and should be replaced with a table-valued parameter or repeated `@p0,@p1,…` parameters in PG.

---

## TdsNatureBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetNature()` | SELECT `* from TdsNature` | `List<T>/entity` | parameterized (no user input) | — |

---

## TdsRateBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetRate(int ayid, int tsId, int PayCode)` | SELECT `* FROM TdsRate WHERE ayid=@ayid AND tsId=@tsId AND PayCode=@PayCode` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetPaycdByTsid(int ayid, int tsId)` | SELECT `* FROM TdsRate WHERE ayid=@ayid AND tsId=@tsId` | `List<T>/entity` | parameterized | — |

---

## TdsaomasterBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from Tdsaomaster` | `List<T>/entity` | parameterized (no user input) | — |
| `GetByCode(int aocode)` | SELECT `* FROM Tdsaomaster WHERE aocode=@aocode` | `List<T>/entity` (FirstOrDefault) | parameterized | — |
| `InsertAomaster(Tdsaomaster obj)` | INSERT INTO Tdsaomaster (34 cols) | `bool/rowcount` | parameterized | `[brackets]` |

---

## Tdsded80Bal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* FROM Tdsded80 ORDER BY sortid` | `List<T>/entity` | parameterized (no user input) | — |
| `GetOne(int ded80id)` | SELECT `* FROM Tdsded80 WHERE ded80id=@ded80id` | `List<T>/entity` (SelectSingle) | parameterized | — |

---

## Tdsnscrate2Bal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from Tdsnscrate2` | `List<T>/entity` | parameterized (no user input) | — |
| `GetRateByDate(string purchaseDate)` | SELECT `* FROM Tdsnscrate2 WHERE pfrom<=@purchaseDate AND pto>=@purchaseDate` | `List<T>/entity` (FirstOrDefault) | parameterized | Date comparison on varchar column — **PG stricter on string/date coercion** |

---

## TdsnscrateBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAll()` | SELECT `* from Tdsnscrate` | `List<T>/entity` | parameterized (no user input) | — |
| `GetRateByDate(string purchaseDate)` | SELECT `* FROM Tdsnscrate WHERE pfrom<=@purchaseDate AND pto>=@purchaseDate` | `List<T>/entity` (FirstOrDefault) | parameterized | Date comparison on varchar column — **PG stricter on string/date coercion** |

---

## UsersBal.cs

| Method | SQL type | Return type | Param/Concat | PG flags |
|--------|----------|-------------|--------------|----------|
| `GetAllUndeletedUsers(string prodkey)` | SELECT `* FROM Users WHERE prodkey=@prodkey AND (IsDeleted IS NULL OR IsDeleted=0)` | `List<T>/entity` | parameterized | — |
| `GetOneUser(int id, string prodKey)` | SELECT `* from Users where userid=@userid and prodKey=@prodKey` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `GetUserForSelectedSubcode(int subCode)` | SELECT `* from Users where selectedPer=@selectedPer` | `List<T>/entity` (SelectSingle) | parameterized | — |
| `SetUserForSelectedSubcode(int userid, int subCode)` | UPDATE `Users set selectedPer=@selectedPer where userid=@userid` | `bool/rowcount` | parameterized | — |
| `SelectOneWithUsernamePassword(string prodkey, string username, string password)` | SELECT `* from Users where username=@username and pwd=@user_password and (prodKey='' or prodKey=@prodKey)` | `List<T>/entity` (SelectSingle → User) | parameterized | **Security critical** — password stored/compared as plaintext; see note below |
| `UpdateProdKey(User user)` (private) | UPDATE `Users set prodKey=@prodKey where userid=@userid` | `void` (Update return ignored) | parameterized | — |
| `ActiveSessions()` | SELECT `distinct(host_name) FROM sys.dm_exec_sessions JOIN sys.dm_exec_connections WHERE host_name!='WIN-I17IUC0QUEP'` | `List<T>/entity` (List\<string\>) | parameterized (no user input) | **`sys.dm_exec_sessions`**, **`sys.dm_exec_connections`** — SQL Server system catalog DMVs with **no PG equivalent**; hardcoded machine name filter |
| `InsertUser(User user)` | INSERT INTO Users (21 cols) | `bool/rowcount` | parameterized | `[brackets]` throughout |
| `InsertUsersBulk(List<User> users)` | Bulk INSERT via SqlBulkCopy | `void` | parameterized | **SqlBulkCopy** → PG `COPY` |
| `UpdateUser(User user)` | UPDATE Users 20 cols WHERE userId=@userId | `bool/rowcount` | parameterized | `[brackets]` |
| `DeleteUser(int id)` | UPDATE `Users set IsDeleted=@IsDeleted where userId=@userid` (soft-delete) | `bool/rowcount` | parameterized | — |

**Auth/login security notes (UsersBal):**
- `SelectOneWithUsernamePassword` is the login entry point. It passes the password directly as a parameter value and does a plain equality match in the database: `pwd = @user_password`. **Passwords are stored in plain text** (or at most a trivial reversible encoding). There is no hashing (no bcrypt, PBKDF2, etc.).  
- The `prodKey` guard `(prodKey='' OR prodKey=@prodKey)` allows any user with an empty prodKey to authenticate for any product key — this is an intentional first-login promotion path but is security-relevant.  
- `ActiveSessions()` queries `sys.dm_exec_sessions` and has a hardcoded hostname `'WIN-I17IUC0QUEP'` — this must be removed entirely or replaced with a PG-compatible mechanism (e.g., `pg_stat_activity`) when porting.

---

## MasterBal Summary

### Totals

| Metric | Count |
|--------|-------|
| Total DB methods inventoried | **98** |
| Files with DB methods | **29** (of 29 source files; DbVariables & MasterBalExtensions have no SQL) |
| `List<T>/entity` return type | **72** |
| `scalar` (int/string from DB) return type | **8** |
| `bool/rowcount` return type | **16** |
| `DataTable` return type | **0** |
| `DataSet` return type | **0** |
| `void` return type | **2** (InsertUsersBulk, InsertGroupsBulk/InsertConsultantBulk) |
| STRING-CONCAT sites (SQL injection risk) | **1** — `TdsEntriesSectionBal.GetByPayCode` (integer IN-list) |
| SqlBulkCopy usages (no direct PG equivalent) | **4** — Users, Groups, Consultant, (commented-out Assessee) |

### How login/auth works in UsersBal

1. The caller provides `prodkey`, `username`, `password` strings.
2. `SelectOneWithUsernamePassword` does a direct `SELECT * FROM Users WHERE username=@username AND pwd=@user_password AND (prodKey='' OR prodKey=@prodKey)` — all parameterized, no string-concat risk.
3. Password is compared as a **plain-text equality** in the database column. No hashing or salting is applied anywhere in this layer. The `pwd` column stores the credential as-is.
4. If the matching user has an empty `prodKey`, it is immediately back-filled via `UpdateProdKey` — tying the user record to this installation's product key on first successful login.
5. `ActiveSessions()` queries `sys.dm_exec_sessions` / `sys.dm_exec_connections` to list other connected clients — this is used for a "who's online" UI feature and has no PG equivalent.

### Top 5 Riskiest Methods to Port

| Rank | Method | File | Risk |
|------|--------|------|------|
| 1 | `InsertAssessee` / `UpdateAssessee` | AssesseeBal.cs | 115-parameter INSERT/UPDATE with binary `profilePic` (byte[]) column; relies on `IDENTITY`/`SCOPE_IDENTITY()` via `InsertAndGetId`; `[bracket]` identifiers throughout; largest and most complex SQL in the project |
| 2 | `ActiveSessions()` | UsersBal.cs | Queries SQL Server DMVs `sys.dm_exec_sessions` and `sys.dm_exec_connections` with a hardcoded machine name — no PG equivalent; must be redesigned entirely |
| 3 | `Save(ReturnDates obj)` | ReturnDatesBal.cs | C# upsert logic catches `SqlException.Number == 2627/2601` (SQL Server unique-violation error codes); must change to catch `NpgsqlException` with `SqlState == "23505"`; or replace with native PG `INSERT … ON CONFLICT DO UPDATE` |
| 4 | `GetLastBillReceiptNo` | BillReceiptsBal.cs | Uses `CONVERT(datetime, col)` × 4 in the WHERE clause for date range filtering on a varchar column — PG requires `::timestamp` cast or proper `DATE/TIMESTAMP` column typing; date storage as string is a schema design issue |
| 5 | `InsertBillAndGetId` / `GetNextBillNo` | BillHeadBal.cs | Both use `ISNULL(Max(BillNo),0)+1` as an inline auto-increment inside the INSERT subquery — PG equivalent is `COALESCE(MAX(billNo),0)+1`; `ISNULL` → `COALESCE` across ~3 methods; concurrent race condition also exists but that's pre-existing |

### Additional Cross-Cutting PG Portability Flags Found

| Flag | Occurrences | Files |
|------|-------------|-------|
| `[square bracket]` identifiers | ~30+ methods | All BAL files with INSERT/UPDATE |
| `ISNULL(` | 3 | BillHeadBal.cs (×3) |
| `CONVERT(datetime,…)` | 4 | BillReceiptsBal.cs |
| `IDENTITY` / `SCOPE_IDENTITY()` via `InsertAndGetId` base method | ~10 | AssesseeBal, AssesseeResStatusBal, BillHeadBal, ConsultantBal, FeePaidMarkingBal, TdsaomasterBal, ReturnDatesBal (indirectly) |
| `sys.dm_exec_*` system catalog | 1 | UsersBal.cs |
| `INFORMATION_SCHEMA` queries | 2 | AssesseeBal.cs, ReturnDatesBal.cs |
| `SqlBulkCopy` (bulk load) | 4 | UsersBal, GroupBal, ConsultantBal (+ commented Assessee) |
| String-stored dates compared with `<=`/`>=` | 2 | TdsnscrateBal.cs, Tdsnscrate2Bal.cs |
| SQL Server error codes in `catch (SqlException ex.Number)` | 1 | ReturnDatesBal.cs |
| `+` string concat for SQL IN-list | 1 | TdsEntriesSectionBal.cs |
| `bit` 0/1 literals in WHERE `IsDeleted=0/1` | ~8 | AssesseeBal, UsersBal, BillHeadBal, BillmastBal, etc. |
| `ORDER BY … DESC` on `IDENTITY` column (implicit assumptions about row ordering) | several | BillHeadBal |
