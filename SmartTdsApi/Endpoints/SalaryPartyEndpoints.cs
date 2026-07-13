using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Landlord (HRA / rent > 1 lakh) and lender (housing-loan interest) PAN + name declared by
/// a salaried employee, for the 24Q Annexure-II SD record. Per-AY salary data — lives in the
/// year DBs (X-Assessment-Year routed), keyed by the employee (subcode + ayid + pcode).
/// Tenant-isolated by subcode via RLS (app.subcodes), like the salary table.
/// </summary>
public sealed record SalaryPartyDto
{
    public string? partyType { get; init; } // "Landlord" | "Lender"
    public string? pan { get; init; }
    public string? name { get; init; }
}

public sealed record SalaryPartyReplaceReq
{
    public int subCode { get; init; }
    public int ayId { get; init; }
    public int pcode { get; init; }
    public List<SalaryPartyDto>? parties { get; init; }
}

public static class SalaryPartyEndpoints
{
    public static void MapSalaryPartyEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/salaryparties").RequireAuthorization();

        // GET /api/salaryparties?subCode=&ayId=&pcode= — landlord/lender rows for an employee.
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId, int pcode) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"select id, subcode, ayid, pcode, partytype, pan, name
                                     from salaryparty
                                     where subcode = @subCode and ayid = @ayId and pcode = @pcode
                                     order by id";
                var rows = await conn.QueryAsync(new CommandDefinition(sql,
                    new { subCode, ayId, pcode }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (Npgsql.PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("ListSalaryParties");

        // PUT /api/salaryparties — replace ALL rows for (subCode, ayId, pcode): delete then insert.
        grp.MapPut("/", async (SalaryPartyReplaceReq body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            if (body.subCode <= 0 || body.ayId <= 0 || body.pcode <= 0)
                return Results.BadRequest(new { error = "subCode, ayId and pcode are required" });

            using var conn = await db.OpenYearAsync(year, ct);
            // Atomic replace: if any insert fails after the delete, the whole set rolls back
            // (the `using` disposes -> rolls back unless we reach Commit). The app.subcodes GUC
            // is session-level (set_config(..., false)), so it survives inside the transaction.
            using var tx = conn.BeginTransaction();
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from salaryparty where subcode = @subCode and ayid = @ayId and pcode = @pcode",
                new { body.subCode, body.ayId, body.pcode }, transaction: tx, cancellationToken: ct));

            if (body.parties != null)
            {
                const string ins = @"insert into salaryparty (subcode, ayid, pcode, partytype, pan, name)
                                     values (@subCode, @ayId, @pcode, @partyType, @pan, @name)";
                foreach (var p in body.parties)
                {
                    // skip fully-blank rows (a grid's empty new-item row)
                    if (string.IsNullOrWhiteSpace(p.pan) && string.IsNullOrWhiteSpace(p.name)) continue;
                    await conn.ExecuteAsync(new CommandDefinition(ins,
                        new { body.subCode, body.ayId, body.pcode, p.partyType, p.pan, p.name },
                        transaction: tx, cancellationToken: ct));
                }
            }
            tx.Commit();
            return Results.NoContent();
        }).WithName("ReplaceSalaryParties");
    }
}
