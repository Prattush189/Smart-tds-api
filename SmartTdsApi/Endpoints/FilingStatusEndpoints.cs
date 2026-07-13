using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Per-assessment-year CRUD for the year-DB table <c>filingstatus</c>
/// (pk=id, cols subcode/ayid + many f*r/f*d/tcs* VARCHAR columns holding the
/// per-quarter return receipt numbers/dates). The X-Assessment-Year header
/// selects the database (same pattern as ChallanEndpoints). Reads return the
/// full row dynamically; writes use the FilingStatusDto whose property names
/// match SmartTdsEntities.FilingStatus 1:1.
/// </summary>
public static class FilingStatusEndpoints
{
    private const string Cols = @"id, subcode, ayid,
        f241r, f241d, f242r, f242d, f243r, f243d, f244r, f244d,
        f261r, f261d, f262r, f262d, f263r, f263d, f264r, f264d,
        f271r, f271d, f272r, f272d, f273r, f273d, f274r, f274d,
        tcs1r, tcs1d, tcs2r, tcs2d, tcs3r, tcs3d, tcs4r, tcs4d";

    public static void MapFilingStatusEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/filingstatus").RequireAuthorization();

        // GET /api/filingstatus?subCode=&ayId=
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {Cols} from filingstatus
                            where subcode = @subCode and ayid = @ayId
                            order by id";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            });
        }).WithName("ListFilingStatus");

        // GET /api/filingstatus/{id}
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {Cols} from filingstatus where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            });
        }).WithName("GetFilingStatus");

        // POST /api/filingstatus — insert, returns { id }.
        grp.MapPost("/", async (FilingStatusDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into filingstatus
                        (subcode, ayid,
                         f241r, f241d, f242r, f242d, f243r, f243d, f244r, f244d,
                         f261r, f261d, f262r, f262d, f263r, f263d, f264r, f264d,
                         f271r, f271d, f272r, f272d, f273r, f273d, f274r, f274d,
                         tcs1r, tcs1d, tcs2r, tcs2d, tcs3r, tcs3d, tcs4r, tcs4d)
                    values
                        (@subCode, @ayId,
                         @f241r, @f241d, @f242r, @f242d, @f243r, @f243d, @f244r, @f244d,
                         @f261r, @f261d, @f262r, @f262d, @f263r, @f263d, @f264r, @f264d,
                         @f271r, @f271d, @f272r, @f272d, @f273r, @f273d, @f274r, @f274d,
                         @tcs1r, @tcs1d, @tcs2r, @tcs2d, @tcs3r, @tcs3d, @tcs4r, @tcs4d)
                    returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            });
        }).WithName("CreateFilingStatus");

        // PUT /api/filingstatus/{id}
        grp.MapPut("/{id:int}", async (int id, FilingStatusDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update filingstatus set
                        subcode = @subCode, ayid = @ayId,
                        f241r = @f241r, f241d = @f241d, f242r = @f242r, f242d = @f242d,
                        f243r = @f243r, f243d = @f243d, f244r = @f244r, f244d = @f244d,
                        f261r = @f261r, f261d = @f261d, f262r = @f262r, f262d = @f262d,
                        f263r = @f263r, f263d = @f263d, f264r = @f264r, f264d = @f264d,
                        f271r = @f271r, f271d = @f271d, f272r = @f272r, f272d = @f272d,
                        f273r = @f273r, f273d = @f273d, f274r = @f274r, f274d = @f274d,
                        tcs1r = @tcs1r, tcs1d = @tcs1d, tcs2r = @tcs2r, tcs2d = @tcs2d,
                        tcs3r = @tcs3r, tcs3d = @tcs3d, tcs4r = @tcs4r, tcs4d = @tcs4d
                    where id = @id";
                var affected = await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    id,
                    body.subCode, body.ayId,
                    body.f241r, body.f241d, body.f242r, body.f242d, body.f243r, body.f243d, body.f244r, body.f244d,
                    body.f261r, body.f261d, body.f262r, body.f262d, body.f263r, body.f263d, body.f264r, body.f264d,
                    body.f271r, body.f271d, body.f272r, body.f272d, body.f273r, body.f273d, body.f274r, body.f274d,
                    body.tcs1r, body.tcs1d, body.tcs2r, body.tcs2d, body.tcs3r, body.tcs3d, body.tcs4r, body.tcs4d
                }, cancellationToken: ct));
                return affected == 0 ? Results.NotFound() : Results.NoContent();
            });
        }).WithName("UpdateFilingStatus");
    }
}

// Write body. Property names match SmartTdsEntities.FilingStatus 1:1 so the BAL
// can POST/PUT the entity directly. id is the server-owned identity column.
public sealed record FilingStatusDto
{
    public int subCode { get; init; }
    public int ayId { get; init; }

    public string? f241r { get; init; } public string? f241d { get; init; }
    public string? f242r { get; init; } public string? f242d { get; init; }
    public string? f243r { get; init; } public string? f243d { get; init; }
    public string? f244r { get; init; } public string? f244d { get; init; }

    public string? f261r { get; init; } public string? f261d { get; init; }
    public string? f262r { get; init; } public string? f262d { get; init; }
    public string? f263r { get; init; } public string? f263d { get; init; }
    public string? f264r { get; init; } public string? f264d { get; init; }

    public string? f271r { get; init; } public string? f271d { get; init; }
    public string? f272r { get; init; } public string? f272d { get; init; }
    public string? f273r { get; init; } public string? f273d { get; init; }
    public string? f274r { get; init; } public string? f274d { get; init; }

    public string? tcs1r { get; init; } public string? tcs1d { get; init; }
    public string? tcs2r { get; init; } public string? tcs2d { get; init; }
    public string? tcs3r { get; init; } public string? tcs3d { get; init; }
    public string? tcs4r { get; init; } public string? tcs4d { get; init; }
}
