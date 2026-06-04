using Dapper;
using Npgsql;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ---------------------------------------------------------------------------
// Standalone CRUD for the three salary child tables (year DB, per-AY):
//   salarynaturedetails, salaryexemptallowances, salaryperquisitedetails
// Each is keyed by salId (FK -> salary.id). These mirror the per-child BAL
// classes (SalaryNatureDetailsBal, SalaryExemptAllowancesBal,
// SalaryPerquisiteDetailsBal). The composite /api/salaries endpoints still
// own parent+children-in-one-shot; these endpoints exist for callers that
// manage children independently.
//
// DTO property names match the SmartTdsEntities child classes exactly so the
// desktop JSON (de)serializer binds them: lowercase id/salId, PascalCase
// nature/amount fields.
// ---------------------------------------------------------------------------

public sealed record SalaryNatureDetailRow
{
    public int id { get; init; }
    public int salId { get; init; }
    public string? NatureDesc { get; init; }
    public string? OthNatOfInc { get; init; }
    public decimal OthAmount { get; init; }
}

public sealed record SalaryPerquisiteDetailRow
{
    public int id { get; init; }
    public int salId { get; init; }
    public string? NatureDesc { get; init; }
    public string? OthNatOfInc { get; init; }
    public decimal OthAmount { get; init; }
}

public sealed record SalaryExemptAllowanceRow
{
    public int id { get; init; }
    public int salId { get; init; }
    public string? SalNatureDesc { get; init; }
    public string? SalOthNatOfInc { get; init; }
    public decimal SalOthAmount { get; init; }
}

public static class SalaryChildEndpoints
{
    private const string YearHeader = "X-Assessment-Year";

    private static bool TryYear(HttpRequest http, out string year, out IResult? bad)
    {
        bad = null;
        if (!http.Headers.TryGetValue(YearHeader, out var v) || string.IsNullOrWhiteSpace(v))
        {
            year = string.Empty;
            bad = Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });
            return false;
        }
        year = v!;
        return true;
    }

    public static void MapSalaryChildEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api").RequireAuthorization();

        // =================================================================
        // salarynaturedetails
        // =================================================================
        grp.MapGet("/salarynaturedetails", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int salId) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"select id as ""id"", salid as ""salId"", naturedesc as ""NatureDesc"",
                                            othnatofinc as ""OthNatOfInc"", othamount as ""OthAmount""
                                     from salarynaturedetails where salid = @salId order by id";
                var rows = await conn.QueryAsync<SalaryNatureDetailRow>(
                    new CommandDefinition(sql, new { salId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("ListSalaryNatureDetails");

        grp.MapPost("/salarynaturedetails", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, SalaryNatureDetailRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"insert into salarynaturedetails (salid, naturedesc, othnatofinc, othamount)
                                     values (@salId, @NatureDesc, @OthNatOfInc, @OthAmount) returning id";
                var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql,
                    new { dto.salId, dto.NatureDesc, dto.OthNatOfInc, dto.OthAmount }, cancellationToken: ct));
                return Results.Ok(new { id });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("CreateSalaryNatureDetail");

        grp.MapPut("/salarynaturedetails/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id, SalaryNatureDetailRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"update salarynaturedetails set
                                         salid = @salId, naturedesc = @NatureDesc,
                                         othnatofinc = @OthNatOfInc, othamount = @OthAmount
                                     where id = @id";
                var n = await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { id, dto.salId, dto.NatureDesc, dto.OthNatOfInc, dto.OthAmount }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("UpdateSalaryNatureDetail");

        grp.MapDelete("/salarynaturedetails/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var n = await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salarynaturedetails where id = @id", new { id }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteSalaryNatureDetail");

        // =================================================================
        // salaryexemptallowances
        // =================================================================
        grp.MapGet("/salaryexemptallowances", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int salId) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"select id as ""id"", salid as ""salId"", salnaturedesc as ""SalNatureDesc"",
                                            salothnatofinc as ""SalOthNatOfInc"", salothamount as ""SalOthAmount""
                                     from salaryexemptallowances where salid = @salId order by id";
                var rows = await conn.QueryAsync<SalaryExemptAllowanceRow>(
                    new CommandDefinition(sql, new { salId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("ListSalaryExemptAllowances");

        grp.MapPost("/salaryexemptallowances", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, SalaryExemptAllowanceRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"insert into salaryexemptallowances (salid, salnaturedesc, salothnatofinc, salothamount)
                                     values (@salId, @SalNatureDesc, @SalOthNatOfInc, @SalOthAmount) returning id";
                var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql,
                    new { dto.salId, dto.SalNatureDesc, dto.SalOthNatOfInc, dto.SalOthAmount }, cancellationToken: ct));
                return Results.Ok(new { id });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("CreateSalaryExemptAllowance");

        grp.MapPut("/salaryexemptallowances/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id, SalaryExemptAllowanceRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"update salaryexemptallowances set
                                         salid = @salId, salnaturedesc = @SalNatureDesc,
                                         salothnatofinc = @SalOthNatOfInc, salothamount = @SalOthAmount
                                     where id = @id";
                var n = await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { id, dto.salId, dto.SalNatureDesc, dto.SalOthNatOfInc, dto.SalOthAmount }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("UpdateSalaryExemptAllowance");

        grp.MapDelete("/salaryexemptallowances/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var n = await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salaryexemptallowances where id = @id", new { id }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteSalaryExemptAllowance");

        // =================================================================
        // salaryperquisitedetails
        // =================================================================
        grp.MapGet("/salaryperquisitedetails", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int salId) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"select id as ""id"", salid as ""salId"", naturedesc as ""NatureDesc"",
                                            othnatofinc as ""OthNatOfInc"", othamount as ""OthAmount""
                                     from salaryperquisitedetails where salid = @salId order by id";
                var rows = await conn.QueryAsync<SalaryPerquisiteDetailRow>(
                    new CommandDefinition(sql, new { salId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("ListSalaryPerquisiteDetails");

        grp.MapPost("/salaryperquisitedetails", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, SalaryPerquisiteDetailRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"insert into salaryperquisitedetails (salid, naturedesc, othnatofinc, othamount)
                                     values (@salId, @NatureDesc, @OthNatOfInc, @OthAmount) returning id";
                var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql,
                    new { dto.salId, dto.NatureDesc, dto.OthNatOfInc, dto.OthAmount }, cancellationToken: ct));
                return Results.Ok(new { id });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("CreateSalaryPerquisiteDetail");

        grp.MapPut("/salaryperquisitedetails/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id, SalaryPerquisiteDetailRow dto) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"update salaryperquisitedetails set
                                         salid = @salId, naturedesc = @NatureDesc,
                                         othnatofinc = @OthNatOfInc, othamount = @OthAmount
                                     where id = @id";
                var n = await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { id, dto.salId, dto.NatureDesc, dto.OthNatOfInc, dto.OthAmount }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("UpdateSalaryPerquisiteDetail");

        grp.MapDelete("/salaryperquisitedetails/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id) =>
        {
            if (!TryYear(http, out var year, out var bad)) return bad!;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var n = await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salaryperquisitedetails where id = @id", new { id }, cancellationToken: ct));
                return n == 0 ? Results.NotFound() : Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." }); }
        }).WithName("DeleteSalaryPerquisiteDetail");
    }
}
