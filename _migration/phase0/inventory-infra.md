# Phase 0 Inventory — Data-Access Infrastructure, Tenancy & Credentials

Scope: DAL plumbing, DB-selection / tenancy mechanism, connection-string construction,
credential handling, and SQL-Server-specific DB admin utilities (backup/restore, schema update).
Target migration: SQL Server -> PostgreSQL (Npgsql).

All paths relative to `C:\SmartTds Backup\ProjectTDS - SQL`.

---

## 1. Tenancy Mechanism (assessment-year-versioned DBs + shared MasterDbTds)

**Confirmed model:** One physical database per assessment year (`SmartTds25`, `SmartTds26`, ...),
all on the **same SQL Server instance**, shared by every firm. The firm is a *column*, not a
separate DB — there is **no per-firm database and no per-firm connection switching** anywhere in
the DAL. A single shared `MasterDbTds` holds cross-year / app-level data (users, application
params, AY master list, backup config). DB selection is purely **by assessment year**.

### The list of databases
`SmartTdsWinUI\Global\Variables.cs:29`
```csharp
public static List<string> DbList = new List<string> { "MasterDbTds", "SmartTds25", "SmartTds26" };
```
This is the authoritative enumeration used by the backup and schema-update loops. **Adding a new
AY (e.g. SmartTds27) requires editing this hardcoded list.**

### How a DB name is chosen

There are **two parallel "DbVariables" holders** plus **two parallel low-level "Variables" holders**,
and they shadow each other:

| Layer | SmartTds (per-AY) | Master (shared) |
|---|---|---|
| BAL holder | `SmartTdsBAL\DbVariables.cs` (`SmartTdsBAL.DbVariables`) | `MasterBal\DbVariables.cs` (`MasterBAL.DbVariables`) |
| DAL holder | `SmartTdsDAL\SmartTdsVariables.cs` | `MasterDAL\MasterVariables.cs` |

Each BAL `DbVariables` has static `u`, `p`, `InstanceName`, `DbName`, `DataSourceString`.
Calling `SetDataSourceString()` on the BAL holder **also pushes the string down into the DAL
holder** (`SmartTdsBAL\DbVariables.cs:16`, `MasterBal\DbVariables.cs:21`).

### DataSourceString trace (instanceName / dbName population), in execution order

1. **App start** — `SmartTdsWinUI\Program.cs:387-404` (`SetInitParams`):
   - Hardcoded defaults `user="sa"`, `pwd="pass.123"` (overridable by a `dbcred.txt` file, lines 389-396).
   - `MasterBAL.DbVariables.DbName = "MasterDbTds"` (line 399), `SmartTdsBAL.DbVariables.DbName = "SmartTds25"` (line 400 — **hardcoded default AY**).
   - Both `SetDataSourceString()` called (lines 403-404). NOTE: `InstanceName` is still null here.

2. **Login** — `SmartTdsWinUI\Masters\Users\FrmLogin.cs:251-327` (`bwLogin_DoWork`):
   - `DbVariables.DbName = "MasterDbTds"` (line 257).
   - **Online mode**: instance + creds come from the GSP auth API response, parsed at lines 295-302:
     `_selectedInstance = param[1] + "," + param[2]` (server,port); `u = param[3]`, `p = param[4]`.
   - **Local mode**: `_selectedInstance = ddInstance.Text` or contents of `instance.txt` (lines 320-323).
   - `InstanceName` set for both holders (line 325), then `SetDataSourceString()` for both (lines 326-327).

3. **Year switch (primary switch point)** — `SmartTdsWinUI\Global\Variables.cs:1096-1109` (`Return.SetYearVariables()`):
   ```csharp
   AyName = ayObj.name;
   SmartTdsBAL.DbVariables.DbName = "SmartTds" + AyName.Substring(2, 2);  // e.g. "SmartTds26"
   SmartTdsBAL.DbVariables.SetDataSourceString();
   ```
   This is how the active per-AY DB flips when the user changes assessment year. The DB name is
   derived from the last two digits of the AY name.

4. **Temporary cross-AY scope** — `SmartTdsWinUI\Common\DbScope.cs` (`RunOnAy` / `TryRunOnAy`):
   - Builds `targetDb = "SmartTds" + targetAyId.ToString("00")` (line 45), flips
     `SmartTdsBAL.DbVariables.DbName`, calls `SetDataSourceString()`, runs the action, **restores in
     `finally`** (lines 54-65). Used for reading the previous year's last-accepted token, etc.
   - `TryRunOnAy` first probes existence via a 5s connection to `master` + `SELECT COUNT(*) FROM
     sys.databases WHERE name=@n` (lines 141-156) with a session-level cache — **this `sys.databases`
     probe is SQL-Server-specific** (PG equivalent: `pg_database`).

5. **Ad-hoc cross-AY (bypasses DbScope)** — `SmartTdsWinUI\Tds\FrmPayee.cs:937-958`
   (`btnImportLastYear_Click`): calls `SmartTdsDAL.SmartTdsVariables.SetDataSourceString(...)`
   directly with `prevDbName = "SmartTds" + prevAyId` and restores the saved string in `finally`.
   **Bug/inconsistency to flag:** uses `"SmartTds" + prevAyId` with **no zero-padding** (line 940),
   unlike the `ToString("00")` convention everywhere else — would produce `"SmartTds9"` for AY 9.

### How the switch physically takes effect
`SmartTdsDAL\ConnectionFactory.cs:9`:
```csharp
public SqlConnection Conn = new SqlConnection(SmartTdsVariables.DataSourceString);
```
The connection string is **read at `ConnectionFactory` construction time** (per-instance field
initializer). Every DAL call `new`s a fresh `ConnectionFactory`, so the next operation after a
`SetDataSourceString()` picks up the new DB. `MasterDAL\ConnectionFactory.cs:14-19` does the same
but rebuilds `Conn` inside `Create()` every call (static). **This pattern — a global mutable
connection string + new connection per op — is the core thing the Npgsql swap must preserve.**

---

## 2. Connection Strings — every build site (file:line) + credentials

The known production server `server8.smartbizindia.com\INST49` appears only in `app.config`
(MasterDbTds design-time string). At runtime the instance is supplied by the GSP API (online)
or the user/instance.txt (local).

| # | File:line | Builder | Credentials | Catalog |
|---|---|---|---|---|
| 1 | `SmartTdsDAL\SmartTdsVariables.cs:15-21` | `SetDataSourceString(instance,db,u,p)` | SQL auth `User ID`/`Password` (plaintext in memory) | per-AY |
| 2 | `MasterDAL\MasterVariables.cs:18-24` | `SetDataSourceString(...)` | SQL auth | MasterDbTds |
| 3 | `SmartTdsBAL\DbVariables.cs:15` | `SetDataSourceString()` (then delegates to #1) | SQL auth | per-AY |
| 4 | `MasterBal\DbVariables.cs:20` | `SetDataSourceString()` (then delegates to #2) | SQL auth | MasterDbTds |
| 5 | `SmartTdsWinUI\Common\DbScope.cs:141-144` | `SqlConnectionStringBuilder` probe (`InitialCatalog="master"`, `ConnectTimeout=5`) | inherits current creds | master |
| 6 | `SmartTdsWinUI\Tds\FrmPayee.cs:946-948` | direct call to #1 | SQL auth | prev-AY |
| 7 | `SmartTdsWinUI\Utility\FrmBackup.cs:160` (Takebackup) | inline string | `User ID`+`Password` from `DbVariables.u/p`; **Integrated Security when `Variables.LiteVer`** (162) | (none — server-level) |
| 8 | `FrmBackup.cs:188-190` (WriteToLogFile) | inline string | SQL auth / Integrated (Lite) | (none) |
| 9 | `FrmBackup.cs:376-378` (GetBackupLoc) | inline string | SQL auth / Integrated (Lite) | MasterDbTds |
| 10 | `FrmBackup.cs:410-412` (SetBackupLoc) | inline string | SQL auth / Integrated (Lite) | MasterDbTds |
| 11 | `FrmBackup.cs:434-436` (UpdateBackupDate) | inline string | SQL auth / Integrated (Lite) | MasterDbTds |
| 12 | `FrmBackup.cs:462` (GetBackupDate) | inline string | SQL auth (no Lite branch here) | MasterDbTds |
| 13 | `SmartTdsWinUI\Utility\FrmUpdateDb.cs:41` (SetConnStr) | inline string | SQL auth | per-db (loops DbList) |
| 14 | `SmartTdsWinUI\app.config:35-43` | 3 design-time `<connectionStrings>` | see below | SmartTds25/26 + MasterDbTds |

### Credential notes (security findings)
- **Hardcoded `sa` / `pass.123`** baked into the EXE: `Program.cs:389-390`. This is the production
  fallback when `dbcred.txt` is absent.
- **app.config MasterDbTds string uses `User ID=sa` with no password** (`app.config:42`) pointed at
  `server8.smartbizindia.com\INST49,50059`. The two `SmartTds25/26` design-time strings use
  `Integrated Security=True` against a dev box `LAPTOP-IN49DRLQ\SQLEXPRESSTDS`
  (`app.config:35-40`). These design-time strings are largely vestigial — the live connection is
  built at runtime by the holders above — but the `sa` exposure is real.
- **app.config encrypted blobs** (`lic`, `name`, `pwd`, `app.config:27-32`) are **DES-encrypted**,
  not the DB credentials — they are the licence/registration fields, decrypted via
  `ImpData.DecryptLocalData` (used at `FrmLogin.cs:169-173`). **DES with hardcoded 8-byte ASCII
  keys**: `ImpData.cs:523-525` — `"CoolFool"` (`bytes`), `"FoolCool"` (`bytesCre`),
  `"BoolMool"` (`bytesLocalData`). These are trivially reversible; effectively obfuscation.
- DB password `p` is held as **plaintext** in the static `DbVariables.p` and concatenated straight
  into connection strings. The GSP API returns instance+creds in clear (`FrmLogin.cs:298-300`).
- `CEncryption.cs` (RSA-2048, public key only) is **unrelated to DB credentials** — it encrypts
  GSP/GST API request payloads. Not in migration scope for credentials.

---

## 3. DAL Pattern (how commands execute + how rows map to entities)

Both `SmartTdsDAL\DbBaseClass.cs` and `MasterDAL\DbBaseClass.cs` are an abstract generic base
`DbBaseClass<TEntity>`. They are **hand-rolled ADO.NET** built directly on
`System.Data.SqlClient.SqlCommand` / `SqlConnection` — **no ORM, no Dapper**.

**Execution primitives** (`SmartTdsDAL\DbBaseClass.cs`):
- `Insert(SqlCommand)` — `ExecuteNonQuery() > 0` (line 18).
- `InsertList(List<SqlCommand>)` — loops, shares one connection, **no explicit transaction** (lines 30-52).
- `InsertAndGetId(SqlCommand)` — appends `";SELECT SCOPE_IDENTITY();"` to CommandText then
  `ExecuteScalar` (lines 54-74). **SCOPE_IDENTITY() is T-SQL-specific** — PG needs
  `RETURNING <id>` or `lastval()`. Same code in `MasterDAL\DbBaseClass.cs:31-53`.
- `InsertBulk(DataTable, tableName)` — uses **`SqlBulkCopy`** with `TableLock | FireTriggers |
  UseInternalTransaction`, BatchSize 10000 (lines 76-108; Master variant lines 55-85).
  **SqlBulkCopy has no Npgsql drop-in** — PG equivalent is `NpgsqlBinaryImporter` (COPY).
- `Update` / `Delete` / `FireRawQuery` — `ExecuteNonQuery` (lines 207-261).
- `ToOneColumn(SqlCommand)` — `ExecuteScalar().ToString()` (lines 188-206).
- `ToList(string)` / `ToList(SqlCommand)` / `SelectSingle(SqlCommand)` — `ExecuteReader` loop.

**Result mapping** — **manual, per-entity, abstract `Map`**:
```csharp
var item = CreateEntity();
Map(reader, item);          // DbBaseClass.cs:119-121, 147-149, 173-176
...
protected abstract void Map(IDataRecord dr, TEntity obj);  // line 263
protected abstract TEntity CreateEntity();                  // line 264
```
Every concrete DAL class implements `Map` with explicit `reader["col"]` reads. So mapping is
**not** DataTable-based and **not** reflection-based in the SmartTds path — it is hand-written
column-by-column. `MasterDAL\DbBaseClass.cs` additionally carries an *unused* reflection helper
`DataReaderMapToList<T>` (lines 265-292) and `ToListSingleColumn` (143-166), and
`CommandExtensions.ColumnExists` (`MasterDAL\CommandExtensions.cs:22-33`).

**Parameters:** `CommandExtension.AddParameter` (`SmartTdsDAL\CommandExtension.cs:10-18`, Master
`CommandExtensions.cs:13-21`) uses provider-neutral `IDbCommand.CreateParameter()` — **good news:
parameter creation is already provider-agnostic.** `AsDataTable<T>` reflection helper feeds bulk copy.

**Migration difficulty assessment:** Because everything is concrete `SqlCommand`/`SqlConnection`
typed (not `IDbCommand`/`DbConnection`), the swap to Npgsql is **mechanical but wide**: every
`SqlCommand` -> `NpgsqlCommand`, `SqlConnection` -> `NpgsqlConnection`, plus per-DAL `Map`
methods stay as-is (column names must match). The hard spots are limited to: (a) `SCOPE_IDENTITY`,
(b) `SqlBulkCopy`, (c) `@`-vs-`:` parameter prefixes in raw SQL strings (Npgsql accepts `@`),
(d) `MultipleActiveResultSets` (MARS — no PG equivalent; nested readers will break).
Manual `Map` means **no auto-mapping safety net** — column-name/case drift won't be caught at compile time.

---

## 4. SQL-Server-specific DDL/Admin with NO direct PostgreSQL equivalent

### `SmartTdsWinUI\Utility\FrmBackup.cs` (backup) — must be fully rewritten
- **`BACKUP DATABASE [db] TO DISK = @filePath`** (line 166). T-SQL backup. **No PG equivalent** —
  replace with `pg_dump` / `pg_basebackup` invocation (out-of-process), or filesystem/`COPY`-based
  export. The current model writes server-side `.bak` files and zips them client-side (Ionic.Zip,
  lines 264-273).
- **OLE Automation logging via `sp_OACreate` / `sp_OAMethod` / `sp_OADestroy`** (lines 200-223),
  preceded by `sp_configure 'Ole Automation Procedures', 1` + `RECONFIGURE` (lines 213-220).
  This makes SQL Server write to a text file through the FileSystemObject COM object. **No PG
  equivalent at all** — and a security anti-pattern. Rewrite as plain client-side `File.AppendAllText`.
- **`SqlDataSourceEnumerator.Instance.GetDataSources()`** (line 105) enumerates local SQL Server
  instances for the instance dropdown. **No PG equivalent** — PG has no network instance browser;
  replace with manual host/port entry.
- `ApplicationParams` reads/writes (`backupLoc`, `lastBackup`) are ordinary CRUD — portable.

### `SmartTdsWinUI\Utility\FrmUpdateDb.cs` (schema versioning / DDL) — rewrite DDL dialect
- **`CREATE TABLE ApplicationParams(Id int IDENTITY(1,1) NOT NULL, ...)`** (line 87) — `IDENTITY`
  is T-SQL; PG uses `GENERATED ... AS IDENTITY` / `serial`.
- **`ALTER TABLE ... ADD CONSTRAINT [PK_...] PRIMARY KEY ([Id])`** with bracket-quoted identifiers
  (line 89) — bracket identifiers `[...]` are T-SQL; PG uses double quotes.
- **`SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='ApplicationParams'`** (line 116) —
  `INFORMATION_SCHEMA` exists in PG but is case-sensitive on identifiers; needs review.
- Per-DB version loop over `Variables.DbList` (lines 156-194): each AY DB carries its own
  `ApplicationParams.ver`; the updater applies incremental DDL when `ImpData.LocalVer > _ver`. The
  framework is portable but each future migration block must be authored in PG SQL.
- The commented-out block at 169-177 shows where historical schema-migration SQL lived (currently empty).

### Other SQL-Server-isms found incidentally (not in the two forms)
- `SCOPE_IDENTITY()` in both `DbBaseClass.InsertAndGetId` (see section 3).
- `sys.databases` existence probe in `DbScope.cs:148-149`.
- `SqlBulkCopy` in both `DbBaseClass.InsertBulk`.
- `MultipleActiveResultSets=True` baked into every connection string (sections 1-2) — MARS.

---

## Migration risk summary (for design decisions)

1. **Global mutable connection-string + per-op `new` connection** is the entire DB-selection
   mechanism. Any Npgsql layer must reproduce `SetDataSourceString()` semantics and the
   "read string at ConnectionFactory construction" timing, or year-switching / `DbScope` breaks.
2. **Hardcoded `DbList`** and **`"SmartTds"+NN`** naming are scattered (Variables.cs:29,
   Variables.cs:1104, DbScope.cs:45, FrmPayee.cs:940 — the last one un-padded). Centralize during migration.
3. **`SqlBulkCopy`, `SCOPE_IDENTITY`, `BACKUP DATABASE`, `sp_OA*`, `sys.databases`,
   `SqlDataSourceEnumerator`, `IDENTITY`/bracket DDL, MARS** are the concrete no-equivalent items.
4. **Credentials:** hardcoded `sa`/`pass.123` (Program.cs:389-390), `sa` in app.config,
   plaintext password in memory and on the wire from the GSP API, DES-with-hardcoded-key
   obfuscation. Migration is a chance to fix, but at minimum behavior must be preserved.
5. **Manual `Map(reader,obj)` per entity** means the Npgsql swap is mechanical but broad and has
   no compile-time column-name safety — schema/case parity between SQL Server and PG is critical.
