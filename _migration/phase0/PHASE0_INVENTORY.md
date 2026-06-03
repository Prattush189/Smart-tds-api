# Phase 0 — Inventory & Effort Estimate
SmartTds: SQL Server → PostgreSQL + central HA API. Generated 2026-06-02.

> Detailed per-file tables live in the sibling files:
> [SmartTdsBAL](inventory-smarttds-bal.md) · [MasterBal](inventory-master-bal.md) · [Infra/Tenancy](inventory-infra.md) · [WinUI direct-DB + Schema](inventory-winui-and-schema.md)

---

## TL;DR — the migration is MUCH cheaper than feared

The single biggest dreaded cost — `DataTable`/`DataSet` → DTO mapping — **does not exist in the BAL**. Every one of the **190 BAL data methods already returns `List<T>`/entities**. The hand-written-SQL philosophy paid off: the porting surface is *the SQL dialect*, not the data shape.

| Metric | Count | Implication |
|---|---|---|
| BAL DB methods (SmartTdsBAL + MasterBal) | **190** (92 + 98) | the queries to port |
| `DataTable`/`DataSet` returns in BAL | **0** | mapping cost ≈ 0 (huge) |
| String-concat SQL (injection risk) | **8** | small, fix during port |
| Direct-DB sites in WinUI (bypass BAL) | **17** | refactor hotspots |
| Entities ≈ tables | **46** (28 Master + 18 Tds) | schema to convert |
| Stored procedures (business logic) | **~0** | all logic is inline SQL ✅ |
| Typed DataSet needing full rewrite | **1** (`MasterDbTdsDataSet`, billing) | cannot be driver-swapped |

**Proc strategy is decided for us:** there are essentially no business stored procs — logic is inline SQL in the BAL. So the plan's "move SQL into the API via Dapper/Npgsql" is not a choice, it's already the shape. No PL/pgSQL porting project.

---

## Tenancy — CONFIRMED (drives the API design)

**One database per assessment year, shared by all firms. Firm is a column, not a database.** There is **no per-firm DB switching anywhere** in the code.

- DBs: `SmartTds25`, `SmartTds26`, … (+ shared `MasterDbTds`) on the **same** instance.
- Switch mechanism: set global `SmartTdsBAL.DbVariables.DbName = "SmartTds" + NN` → call `SetDataSourceString()` → rebuilds global `DataSourceString` → `ConnectionFactory` reads it on construction (every DAL op `new`s a fresh factory).
- Primary switch point: `Variables.SetYearVariables()` (`Variables.cs:1104`). Temp cross-year scoping: `DbScope.RunOnAy/TryRunOnAy` (restores in `finally`). DB enumeration: `Variables.DbList` (`Variables.cs:29`). Startup default: `SmartTds25`/`MasterDbTds` (`Program.cs`).

**API implication:** the central API's per-request routing is `(assessmentYear) → database`, NOT `(tenant) → database`. The existing global-mutable-string pattern maps cleanly onto a per-request "set the AY, open the connection" model. Auth still needs a firm/user identity (for licensing + row scoping), but DB selection is by year. **Latent bug to fix:** `FrmPayee.cs:940` builds prev-year DB name without zero-padding (`"SmartTds"+prevAyId` vs the `ToString("00")` convention everywhere else).

---

## The real PostgreSQL rewrite cost (the long pole, now sized)

Concentrated in a known, finite set of T-SQL idioms — find-and-replace-grade, not redesign-grade, except where noted:

| T-SQL idiom | Where | PG fix | Effort |
|---|---|---|---|
| `SCOPE_IDENTITY()` / `@@IDENTITY` | pervasive (every identity insert) | `INSERT … RETURNING id` | mechanical but everywhere |
| `ISNULL(` | ~7 sites | `COALESCE(` | trivial |
| `TOP n` | ~4 sites | `LIMIT n` | trivial |
| `[bracket]` identifiers | 80+ queries | `"double-quote"` or bare | cosmetic, bulk |
| `CONVERT(datetime, …)` | BillReceiptsBal (4×) | `to_date`/`to_timestamp` | low |
| Cross-DB 3-part name `[MasterDbTds].[dbo].[TdsEntriesSection]` | TdsPayeeBal | **no PG equivalent** — needs FK/lookup or cross-DB strategy | ⚠️ design |
| `SqlBulkCopy` | 4 sites (Users, Groups, Consultant, Assessee) | `COPY FROM` (Npgsql binary import) | medium |
| SQL error codes `2627/2601` in `catch` | ReturnDatesBal | `NpgsqlException.SqlState == "23505"` | low |
| `sys.dm_exec_*` DMVs (`ActiveSessions`) | UsersBal | **redesign** — track sessions in app/API | ⚠️ design |
| Batch `UPDATE … FROM … (VALUES …)` | TdsEntryBal.UpdateChIdBatch | PG supports `UPDATE … FROM (VALUES …)` w/ tweaks | medium |
| DDL-from-code (`IDENTITY`, `ALTER TABLE ADD BIT`) | Pump.cs, FrmUpdateDb, EnsureItdColumn | PG DDL (`GENERATED … AS IDENTITY`, `boolean`) | low |

⚠️ **Two genuine design items, not mechanical:** the cross-database 3-part name, and the DMV-based active-session query. Everything else is volume, not difficulty.

---

## Schema & data-type risks (a TAX app — correctness matters)

1. **🔴 Money stored as `double`/`float`.** Monetary fields (`TdsDeduct`, `Cess`, `GrndTotal`, `Tax`, …) are `double` in C#, almost certainly `float` in SQL Server. Migrate to **`numeric(18,4)`** to stop floating-point rounding drift in financial totals. Verify rounding behavior doesn't change reported figures.
2. **🟠 Dates stored as `dd/MM/yyyy` strings** (`DatePayment`, `ChallanDt`, `dob`, …), not `date` columns. First pass: keep as `text`. Then convert column-by-column after a format audit (watch the `CONVERT(datetime,…)` queries that parse them).
3. Standard type map: `bit`→`boolean`, `nvarchar`→`text`, `int IDENTITY`→`integer GENERATED ALWAYS AS IDENTITY`, `datetime`→`timestamp`, `uniqueidentifier`→`uuid`, `money`→`numeric`.

**GAP:** no `.sql` schema script exists in the repo. To build the PG schema in Phase 1 we need **either** a live schema dump of `SmartTds26` + `MasterDbTds`, **or** we derive `CREATE TABLE`s from the 46 entity classes (the [schema doc](inventory-winui-and-schema.md) already drafts this) and reconcile against the live DB. A live dump is the reliable path.

---

## Infrastructure that must be rebuilt for PostgreSQL

- **`FrmBackup.cs`** — uses `BACKUP DATABASE`, `sp_configure 'Ole Automation Procedures'` + `sp_OACreate/sp_OAMethod` (OLE file logging), `SqlDataSourceEnumerator`. → replace with `pg_dump`/`pg_basebackup` + WAL archiving (this becomes Phase 4 backup story).
- **`FrmUpdateDb.cs`** — emits T-SQL DDL with `IDENTITY`/brackets. → PG DDL + a real migration tool (e.g. versioned scripts).
- **`DbBaseClass`** (both DAL projects) — hand-rolled `Map(reader, obj)` on concrete `SqlCommand`/`SqlConnection`, `SqlBulkCopy`, `SCOPE_IDENTITY()`. → Npgsql + Dapper; mechanical but wide, zero compile-time column safety today.
- **`DbScope`** — probes `sys.databases`. → `pg_catalog.pg_database`.
- Every connection string carries `MultipleActiveResultSets=True` (MARS) — no PG equivalent; verify no code relies on interleaved readers on one connection.

---

## Security debt (fix during migration, don't carry forward)

- 🔴 **Hardcoded `sa` / `pass.123`** (`Program.cs:389-390`) and `User ID=sa` in `app.config`. Kill — least-privilege PG role, secrets out of the client.
- 🔴 Plaintext passwords in memory and over the GSP/portal API.
- 🟠 DES with hardcoded keys (`CoolFool`/`FoolCool`/`BoolMool`) for licence-field obfuscation — not real crypto.
- 🟠 8 string-concat SQL sites — parameterize during the port (7 in TdsEntryBal, 1 in TdsPayeeBal/TdsEntriesSectionBal).
- The big structural win the migration delivers: **client holds zero DB credentials** (talks only to API + token).

---

## Risk register (ranked)

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| 1 | Cross-DB 3-part name + DMV session query need redesign, not port | High | resolve design before bulk port (Phase 1/2) |
| 2 | Money-as-float → rounding errors in tax figures | High | convert to `numeric`, reconcile totals 1:1 |
| 3 | No schema script → migration needs live DB dump | High | obtain `SmartTds26`+`MasterDbTds` dump |
| 4 | `MasterDbTdsDataSet` (billing) can't be driver-swapped | Medium | rewrite billing CRUD as BAL+Dapper |
| 5 | 17 direct-DB sites in WinUI bypass BAL | Medium | route through API like everything else |
| 6 | WAN chattiness once DB is remote (plan Phase 3) | Medium | coarse-grained endpoints per screen |
| 7 | Dates-as-strings break PG date queries | Medium | text first, audited conversion later |

---

## Phase 0 EXIT — met ✅
Architecture understood, DAL/BAL inventory complete (190 methods classified), schema drafted from entities, T-SQL portability catalogued, tenancy confirmed, risk register produced.

**One external dependency to start Phase 1:** a schema dump (and ideally one firm's data) from live `SmartTds26` + `MasterDbTds`. Without it, we proceed by deriving schema from entities and reconcile later.

## → Phase 1 preview (PostgreSQL schema & data migration)
1. Build PG schema (from live dump, or entity-derived CREATE scripts) — apply the type map (money→numeric, dates→text-then-date).
2. Stand up `MasterDbTds` (shared) + one `SmartTds26` as the per-year template.
3. Repeatable SQL Server→PG migration script w/ row-count + checksum reconciliation.
4. Resolve the 2 design items (cross-DB name, session tracking) before they block the bulk port.
