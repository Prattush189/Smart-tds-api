using Dapper;
using SmartTdsApi.Data;
using SmartTdsApi.Models;

namespace SmartTdsApi.Endpoints;

public static class AssesseeEndpoints
{
    public static void MapAssesseeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/assessees").RequireAuthorization();

        // List (shared master data — not year-scoped)
        grp.MapGet("/", async (IDbConnectionFactory db, CancellationToken ct, int take = 200) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = @"select subcode, tradename, firstname, lastname, pan,
                               assesseestatus, mobileprimary, emailprimary
                        from assessee
                        where isdeleted = false
                        order by tradename
                        limit @take";
            var rows = await conn.QueryAsync<AssesseeDto>(
                new CommandDefinition(sql, new { take }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListAssessees");

        grp.MapGet("/{subCode:int}", async (int subCode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = @"select subcode, tradename, firstname, lastname, pan,
                               assesseestatus, mobileprimary, emailprimary
                        from assessee where subcode = @subCode and isdeleted = false";
            var row = await conn.QueryFirstOrDefaultAsync<AssesseeDto>(
                new CommandDefinition(sql, new { subCode }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetAssessee");
    }
}
