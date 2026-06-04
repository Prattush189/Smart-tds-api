using Dapper;
using Npgsql;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ──────────────────────────────────────────────────────────────────────────
// Specialized TdsEntry endpoints (aggregates, batch insert/link, bulk delete,
// soft-delete, unlink) that back the previously-stubbed TdsEntryBal methods.
// All routes are year-DB scoped via the X-Assessment-Year header, exactly like
// TdsEntryEndpoints. Registered by the orchestrator (Program.cs) via
// MapTdsEntryExtraEndpoints — do NOT register here.
// ──────────────────────────────────────────────────────────────────────────

public sealed record ScalarTotalResult
{
    public decimal Total { get; init; }
}

public sealed record LinkChallanRequest
{
    public int ChId { get; init; }
    public int[] Ids { get; init; } = System.Array.Empty<int>();
}

public sealed record BulkIdsRequest
{
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public int[] Ids { get; init; } = System.Array.Empty<int>();
}

public static class TdsEntryExtraEndpoints
{
    private const string YearHeader = "X-Assessment-Year";

    // Whitelist of summable numeric columns. The legacy SQL concatenated the
    // caller-supplied colName straight into `sum(<col>)` (a SQL-injection
    // vector); here we map the BAL property/column name to a known physical
    // column and reject anything else.
    private static readonly Dictionary<string, string> SummableColumns =
        new(System.StringComparer.OrdinalIgnoreCase)
        {
            ["amtpay"]      = "amtpay",
            ["AmtPay"]      = "amtpay",
            ["tdsdeduct"]   = "tdsdeduct",
            ["TdsDeduct"]   = "tdsdeduct",
            ["surcharge"]   = "surcharge",
            ["Surcharge"]   = "surcharge",
            ["surdeduct"]   = "surdeduct",
            ["SurDeduct"]   = "surdeduct",
            ["cess"]        = "cess",
            ["Cess"]        = "cess",
            ["totaltds2"]   = "totaltds2",
            ["TotalTds2"]   = "totaltds2",
            ["tdsdedlater"] = "tdsdedlater",
            ["TdsDedLater"] = "tdsdedlater",
            ["tdsrate"]     = "tdsrate",
            ["TdsRate"]     = "tdsrate",
            ["surdeducted"] = "surdeduct",
            ["actualtds"]   = "actualtds",
            ["ActualTds"]   = "actualtds",
            ["chinterest"]  = "chinterest",
            ["ChInterest"]  = "chinterest",
            ["chtdsdep"]    = "chtdsdep",
            ["ChTdsDep"]    = "chtdsdep",
        };

    private static bool TryResolveColumn(string? colName, out string column)
    {
        column = string.Empty;
        if (string.IsNullOrWhiteSpace(colName)) return false;
        return SummableColumns.TryGetValue(colName.Trim(), out column!);
    }

    public static void MapTdsEntryExtraEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tdsentries").RequireAuthorization();

        // ── GET /api/tdsentries/sum?payeeId=&subCode=&ayId=&section=&column=&formType=
        // SELECT sum(<column>) FROM tdsentry WHERE payeeid+subcode+ayid+section+formtype
        // section is optional (omit for the no-section overload).
        grp.MapGet("/sum", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            string column,
            int? payeeId,
            int? section,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            if (!TryResolveColumn(column, out var col))
                return Results.BadRequest(new { error = $"Unknown or non-summable column '{column}'." });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);

                var sql = new System.Text.StringBuilder(
                    $"select coalesce(sum({col}), 0) from tdsentry where subcode = @subCode and ayid = @ayId");
                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);

                if (payeeId.HasValue) { sql.Append(" and payeeid = @payeeId"); param.Add("payeeId", payeeId.Value); }
                if (section.HasValue) { sql.Append(" and section = @section"); param.Add("section", section.Value); }
                if (!string.IsNullOrWhiteSpace(formType)) { sql.Append(" and formtype = @formType"); param.Add("formType", formType); }

                var total = await conn.ExecuteScalarAsync<decimal>(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new ScalarTotalResult { Total = total });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("SumTdsEntryColumn");

        // ── GET /api/tdsentries/sumsections?payeeId=&subCode=&ayId=&column=&formType=&sections=1,2,3
        // SELECT sum(<column>) FROM tdsentry WHERE ... AND section IN (sections)
        grp.MapGet("/sumsections", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            string column,
            string sections,
            int? payeeId,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            if (!TryResolveColumn(column, out var col))
                return Results.BadRequest(new { error = $"Unknown or non-summable column '{column}'." });

            int[] sectionIds;
            try
            {
                sectionIds = (sections ?? string.Empty)
                    .Split(',', System.StringSplitOptions.RemoveEmptyEntries | System.StringSplitOptions.TrimEntries)
                    .Select(int.Parse)
                    .ToArray();
            }
            catch (System.FormatException)
            {
                return Results.BadRequest(new { error = "sections must be a comma-separated list of integers." });
            }

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);

                var sql = new System.Text.StringBuilder(
                    $"select coalesce(sum({col}), 0) from tdsentry where subcode = @subCode and ayid = @ayId");
                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);

                if (payeeId.HasValue) { sql.Append(" and payeeid = @payeeId"); param.Add("payeeId", payeeId.Value); }
                if (!string.IsNullOrWhiteSpace(formType)) { sql.Append(" and formtype = @formType"); param.Add("formType", formType); }
                if (sectionIds.Length > 0) { sql.Append(" and section = any(@sections)"); param.Add("sections", sectionIds); }

                var total = await conn.ExecuteScalarAsync<decimal>(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new ScalarTotalResult { Total = total });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("SumTdsEntryColumnSections");

        // ── GET /api/tdsentries/monthlysum?payeeId=&subCode=&ayId=&section=&column=&formType=&monthYear=MM/yyyy
        // SELECT sum(<column>) WHERE ... AND substring(datepayment, 4, 7) = @monthYear
        // (datepayment is dd/MM/yyyy; chars 4-10 = MM/yyyy)
        grp.MapGet("/monthlysum", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            int section,
            string column,
            string monthYear,
            int? payeeId,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            if (!TryResolveColumn(column, out var col))
                return Results.BadRequest(new { error = $"Unknown or non-summable column '{column}'." });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);

                var sql = new System.Text.StringBuilder(
                    $@"select coalesce(sum({col}), 0) from tdsentry
                       where subcode = @subCode and ayid = @ayId and section = @section
                         and substring(datepayment, 4, 7) = @monthYear");
                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);
                param.Add("section", section);
                param.Add("monthYear", monthYear);

                if (payeeId.HasValue) { sql.Append(" and payeeid = @payeeId"); param.Add("payeeId", payeeId.Value); }
                if (!string.IsNullOrWhiteSpace(formType)) { sql.Append(" and formtype = @formType"); param.Add("formType", formType); }

                var total = await conn.ExecuteScalarAsync<decimal>(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new ScalarTotalResult { Total = total });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("MonthlySumTdsEntryColumn");

        // ── POST /api/tdsentries/linkchallan  body { chId, ids:[...] }
        // UPDATE tdsentry SET chid=@ChId WHERE id = any(@Ids)
        grp.MapPost("/linkchallan", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            LinkChallanRequest req) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            var ids = req?.Ids ?? System.Array.Empty<int>();
            if (ids.Length == 0) return Results.Ok(new { count = 0 });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = "update tdsentry set chid = @chId where id = any(@ids)";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { chId = req!.ChId, ids }, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("LinkChallanTdsEntries");

        // ── POST /api/tdsentries/batch  body [ ...entries ]  → bulk insert, returns { ids, count }
        grp.MapPost("/batch", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            TdsEntryDto[] entries) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            if (entries is null || entries.Length == 0) return Results.Ok(new { ids = System.Array.Empty<int>(), count = 0 });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                if (conn is NpgsqlConnection npg && npg.State != System.Data.ConnectionState.Open)
                    await npg.OpenAsync(ct);

                const string sql =
                    @"insert into tdsentry
                        (payeeid, chid, subcode, ayid,
                         payeename, payername, section, nature, descrp,
                         datepayment, datededuct, typededuct,
                         amtpay, tdsrate, surcharge, tdsdeduct, surdeduct, cess,
                         datedeposit, totaltds2, tdsdedlater,
                         formtype, tdsapp, ack15ca, certno,
                         dtvalf, dtvalt, dtpaying, dtcomm,
                         evalid, actualtds, actualrate,
                         chinterest, chtdsdep, deductioncode, pcode)
                      values
                        (@payeeId, @chId, @subCode, @ayId,
                         @payeeName, @payerName, @section, @nature, @descrp,
                         @datePayment, @dateDeduct, @typeDeduct,
                         @amtPay, @tdsRate, @surcharge, @tdsDeduct, @surDeduct, @cess,
                         @dateDeposit, @totalTds2, @tdsDedLater,
                         @formType, @tdsApp, @ack15Ca, @certNo,
                         @dtValF, @dtValT, @dtPaying, @dtComm,
                         @eValid, @actualTds, @actualRate,
                         @chInterest, @chTdsDep, @deductionCode, @pCode)
                      returning id";

                using var tx = conn.BeginTransaction();
                var ids = new List<int>(entries.Length);
                foreach (var dto in entries)
                {
                    var newId = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, new
                    {
                        payeeId = dto.PayeeId, chId = dto.ChId, subCode = dto.SubCode, ayId = dto.AyId,
                        payeeName = dto.PayeeName, payerName = dto.PayerName, section = dto.Section,
                        nature = dto.Nature, descrp = dto.Descrp,
                        datePayment = dto.DatePayment, dateDeduct = dto.DateDeduct, typeDeduct = dto.TypeDeduct,
                        amtPay = dto.AmtPay, tdsRate = dto.TdsRate, surcharge = dto.Surcharge,
                        tdsDeduct = dto.TdsDeduct, surDeduct = dto.SurDeduct, cess = dto.Cess,
                        dateDeposit = dto.DateDeposit, totalTds2 = dto.TotalTds2, tdsDedLater = dto.TdsDedLater,
                        formType = dto.FormType, tdsApp = dto.TdsApp, ack15Ca = dto.Ack15Ca, certNo = dto.CertNo,
                        dtValF = dto.DtValF, dtValT = dto.DtValT, dtPaying = dto.DtPaying, dtComm = dto.DtComm,
                        eValid = dto.EValid, actualTds = dto.ActualTds, actualRate = dto.ActualRate,
                        chInterest = dto.ChInterest, chTdsDep = dto.ChTdsDep,
                        deductionCode = dto.DeductionCode, pCode = dto.PCode
                    }, transaction: tx, cancellationToken: ct));
                    ids.Add(newId);
                }
                tx.Commit();
                return Results.Ok(new { ids, count = ids.Count });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("BatchInsertTdsEntries");

        // ── POST /api/tdsentries/cleardedlater?payeeId=&subCode=&ayId=&section=&formType=
        // UPDATE tdsentry SET tdsdedlater=0 WHERE ... AND tdsdeduct=0 AND tdsdedlater<>0
        grp.MapPost("/cleardedlater", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int payeeId,
            int subCode,
            int ayId,
            int section,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                var sql = new System.Text.StringBuilder(
                    @"update tdsentry set tdsdedlater = 0
                      where payeeid = @payeeId and subcode = @subCode and ayid = @ayId and section = @section
                        and coalesce(tdsdeduct, 0) = 0 and coalesce(tdsdedlater, 0) <> 0");
                var param = new DynamicParameters();
                param.Add("payeeId", payeeId);
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);
                param.Add("section", section);
                if (!string.IsNullOrWhiteSpace(formType)) { sql.Append(" and formtype = @formType"); param.Add("formType", formType); }

                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("ClearCaughtUpTdsDedLater");

        // ── DELETE /api/tdsentries/all?subCode=&ayId=&formTypes=24Q,26Q&quarter=0
        // Hard delete for an AY. formTypes optional (comma list); quarter 1-4 filters
        // datepayment month (dd/MM/yyyy chars 4-5); quarter<=0 means all months.
        grp.MapDelete("/all", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            string? formTypes,
            int? quarter) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                var sql = new System.Text.StringBuilder(
                    "delete from tdsentry where subcode = @subCode and ayid = @ayId");
                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);

                var fts = (formTypes ?? string.Empty)
                    .Split(',', System.StringSplitOptions.RemoveEmptyEntries | System.StringSplitOptions.TrimEntries)
                    .ToArray();
                if (fts.Length > 0) { sql.Append(" and formtype = any(@formTypes)"); param.Add("formTypes", fts); }

                var months = QuarterMonths(quarter ?? 0);
                if (months is not null) { sql.Append(" and substring(datepayment, 4, 2) = any(@months)"); param.Add("months", months); }

                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteAllTdsEntriesForAy");

        // ── DELETE /api/tdsentries/bychallan?chId=&subCode=&ayId=&formType=
        // DELETE FROM tdsentry WHERE chid+subcode+ayid (+formtype)
        grp.MapDelete("/bychallan", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int chId,
            int subCode,
            int ayId,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                var sql = new System.Text.StringBuilder(
                    "delete from tdsentry where chid = @chId and subcode = @subCode and ayid = @ayId");
                var param = new DynamicParameters();
                param.Add("chId", chId);
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);
                if (!string.IsNullOrWhiteSpace(formType)) { sql.Append(" and formtype = @formType"); param.Add("formType", formType); }

                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteTdsEntriesByChallan");

        // ── DELETE /api/tdsentries/bypayee?payeeId=&subCode=&ayId=
        // The legacy method was named SoftDeleteByPayeeId (UPDATE SET IsDeleted=1),
        // but the PG tdsentry table has NO isdeleted column. It is called from
        // PayeeBal.DeletePayeeCascade immediately before the payee row is deleted,
        // so the effective intent is to remove that payee's entries → HARD DELETE.
        grp.MapDelete("/bypayee", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int payeeId,
            int subCode,
            int ayId) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql =
                    "delete from tdsentry where payeeid = @payeeId and subcode = @subCode and ayid = @ayId";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { payeeId, subCode, ayId }, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteTdsEntriesByPayee");

        // ── POST /api/tdsentries/unlinkchallan?chId=&subCode=&ayId=
        // UPDATE tdsentry SET chid=null, datedeposit=null WHERE chid+subcode+ayid
        grp.MapPost("/unlinkchallan", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int chId,
            int subCode,
            int ayId) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql =
                    "update tdsentry set chid = null, datedeposit = null where chid = @chId and subcode = @subCode and ayid = @ayId";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { chId, subCode, ayId }, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("UnlinkTdsEntriesByChallan");

        // ── POST /api/tdsentries/delete-by-ids   body { subCode, ayId, ids:[] }
        // Hard-delete tdsentry rows by an explicit id list (bulk import cleanup).
        // PG ANY(@Ids) handles any list size in one statement (no 2100-param limit).
        grp.MapPost("/delete-by-ids", async (BulkIdsRequest body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });
            if (body?.Ids == null || body.Ids.Length == 0) return Results.Ok(new { count = 0 });
            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = "delete from tdsentry where subcode = @SubCode and ayid = @AyId and id = ANY(@Ids)";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { body.SubCode, body.AyId, body.Ids }, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteTdsEntriesByIds");
    }

    // Financial-quarter → list of dd/MM/yyyy month tokens (matches the legacy
    // TdsEntryBal.QuarterMonthSql). Returns null for "all months".
    private static string[]? QuarterMonths(int quarter) => quarter switch
    {
        1 => new[] { "04", "05", "06" }, // Apr-Jun
        2 => new[] { "07", "08", "09" }, // Jul-Sep
        3 => new[] { "10", "11", "12" }, // Oct-Dec
        4 => new[] { "01", "02", "03" }, // Jan-Mar
        _ => null,
    };
}
