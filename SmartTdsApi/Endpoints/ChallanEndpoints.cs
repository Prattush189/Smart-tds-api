using Dapper;
using Npgsql;
using SmartTdsApi.Data;
using SmartTdsApi.Models;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Full projection of smarttds&lt;year&gt;.addchallan (per-year routed data).
/// Mirrors SmartTdsEntities.AddChallan so the desktop BAL can round-trip every
/// column on insert/get/update. (The slim ChallanDto in Models is kept for the
/// typed ApiClient.GetChallansAsync convenience method.)
/// </summary>
public sealed record AddChallanDto
{
    public int Id { get; init; }
    public int ChId { get; init; }
    public int AyId { get; init; }
    public int SubCode { get; init; }
    public string? ChallanDt { get; init; }
    public string? ChallanNo { get; init; }
    public double TotalTds { get; init; }
    public double Tax { get; init; }
    public double SurChrg { get; init; }
    public double Cess { get; init; }
    public double Total { get; init; }
    public double Interest { get; init; }
    public string? Others { get; init; }
    public double Fee234E { get; init; }
    public double GrndTotal { get; init; }
    public string? NameBnk { get; init; }
    public string? Address { get; init; }
    public string? BranchCd { get; init; }
    public string? Mode { get; init; }
    public string? CheqNo { get; init; }
    public string? DrawnOn { get; init; }
    public string? MinorCd { get; init; }
    public string? ActualTds { get; init; }
    public string? DeductedTds { get; init; }
    public string? DepositedTds { get; init; }
    public double IntQ1 { get; init; }
    public double IntQ2 { get; init; }
    public double IntQ3 { get; init; }
    public double IntQ4 { get; init; }
    public string? FormType { get; init; }
    public bool IsFromItdPortal { get; init; }
}

public sealed record DeleteByChIdsReq
{
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public int[] ChIds { get; init; } = System.Array.Empty<int>();
}

public static class ChallanEndpoints
{
    public const string YearHeader = "X-Assessment-Year";

    private const string SelectColumns = @"id, chid, ayid, subcode, challandt, challanno,
                   totaltds, tax, surchrg, cess, total, interest, others,
                   fee234e, grndtotal, namebnk, address, branchcd, mode,
                   cheqno, drawnon, minorcd, actualtds, deductedtds, depositedtds,
                   intq1, intq2, intq3, intq4, formtype, isfromitdportal";

    public static void MapChallanEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/challans").RequireAuthorization();

        // List challans for a firm in a given assessment year.
        // The YEAR (header) selects the database; subCode filters the firm within it.
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int subCode) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                var sql = $@"select {SelectColumns}
                            from addchallan
                            where subcode = @subCode
                            order by id";
                var rows = await conn.QueryAsync<AddChallanDto>(
                    new CommandDefinition(sql, new { subCode }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000") // invalid_catalog_name
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("ListChallans");

        // GET /api/challans/{id}
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                var sql = $@"select {SelectColumns} from addchallan where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync<AddChallanDto>(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("GetChallan");

        // POST /api/challans  — insert, returns { id }
        grp.MapPost("/", async (AddChallanDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = @"
                    insert into addchallan
                        (chid, ayid, subcode, challandt, challanno, totaltds, tax,
                         surchrg, cess, total, interest, others, fee234e, grndtotal,
                         namebnk, address, branchcd, mode, cheqno, drawnon, minorcd,
                         actualtds, deductedtds, depositedtds, intq1, intq2, intq3, intq4,
                         formtype, isfromitdportal)
                    values
                        (@ChId, @AyId, @SubCode, @ChallanDt, @ChallanNo, @TotalTds, @Tax,
                         @SurChrg, @Cess, @Total, @Interest, @Others, @Fee234E, @GrndTotal,
                         @NameBnk, @Address, @BranchCd, @Mode, @CheqNo, @DrawnOn, @MinorCd,
                         @ActualTds, @DeductedTds, @DepositedTds, @IntQ1, @IntQ2, @IntQ3, @IntQ4,
                         @FormType, @IsFromItdPortal)
                    returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("CreateChallan");

        // PUT /api/challans/{id}
        grp.MapPut("/{id:int}", async (int id, AddChallanDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = @"
                    update addchallan set
                        chid            = @ChId,
                        ayid            = @AyId,
                        subcode         = @SubCode,
                        challandt       = @ChallanDt,
                        challanno       = @ChallanNo,
                        totaltds        = @TotalTds,
                        tax             = @Tax,
                        surchrg         = @SurChrg,
                        cess            = @Cess,
                        total           = @Total,
                        interest        = @Interest,
                        others          = @Others,
                        fee234e         = @Fee234E,
                        grndtotal       = @GrndTotal,
                        namebnk         = @NameBnk,
                        address         = @Address,
                        branchcd        = @BranchCd,
                        mode            = @Mode,
                        cheqno          = @CheqNo,
                        drawnon         = @DrawnOn,
                        minorcd         = @MinorCd,
                        actualtds       = @ActualTds,
                        deductedtds     = @DeductedTds,
                        depositedtds    = @DepositedTds,
                        intq1           = @IntQ1,
                        intq2           = @IntQ2,
                        intq3           = @IntQ3,
                        intq4           = @IntQ4,
                        formtype        = @FormType,
                        isfromitdportal = @IsFromItdPortal
                    where id = @id";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new
                    {
                        id,
                        body.ChId, body.AyId, body.SubCode, body.ChallanDt, body.ChallanNo,
                        body.TotalTds, body.Tax, body.SurChrg, body.Cess, body.Total, body.Interest,
                        body.Others, body.Fee234E, body.GrndTotal, body.NameBnk, body.Address,
                        body.BranchCd, body.Mode, body.CheqNo, body.DrawnOn, body.MinorCd,
                        body.ActualTds, body.DeductedTds, body.DepositedTds,
                        body.IntQ1, body.IntQ2, body.IntQ3, body.IntQ4,
                        body.FormType, body.IsFromItdPortal
                    }, cancellationToken: ct));
                return affected == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("UpdateChallan");

        // DELETE /api/challans/all?subCode=&ayId=  — bulk hard delete of every
        // addchallan row for a firm in this AY database (no isdeleted column).
        grp.MapDelete("/all", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int subCode, int ayId) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = "delete from addchallan where subcode = @subCode and ayid = @ayId";
                await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("DeleteAllChallansForAy");

        // DELETE /api/challans/{id}  — hard delete (addchallan has no isdeleted column)
        grp.MapDelete("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = "delete from addchallan where id = @id";
                await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("DeleteChallan");

        // POST /api/challans/delete-by-chids  body { subCode, ayId, chIds:[] }
        // Hard-delete every addchallan row whose chId is in the list (bulk cleanup).
        grp.MapPost("/delete-by-chids", async (DeleteByChIdsReq body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });
            if (body?.ChIds == null || body.ChIds.Length == 0) return Results.Ok(new { count = 0 });
            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);
                const string sql = "delete from addchallan where subcode = @SubCode and ayid = @AyId and chid = ANY(@ChIds)";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { body.SubCode, body.AyId, body.ChIds }, cancellationToken: ct));
                return Results.Ok(new { count = affected });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteChallansByChIds");
    }
}
