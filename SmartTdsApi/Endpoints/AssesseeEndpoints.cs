using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

public static class AssesseeEndpoints
{
    public static void MapAssesseeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/assessees").RequireAuthorization();

        // List (full rows, scoped by JWT prodkey — desktop loads all at startup)
        grp.MapGet("/", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from assessee
                                 where prodkey = @pk and isdeleted = false
                                 order by tradename";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListAssessees");

        grp.MapGet("/{subCode:int}", async (int subCode, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from assessee where subcode = @subCode and prodkey = @pk";
            var row = await conn.QueryFirstOrDefaultAsync(
                new CommandDefinition(sql, new { subCode, pk = prodkey }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetAssessee");
    }
}
