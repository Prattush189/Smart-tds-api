using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

public static class FirmDataEndpoints
{
    public static void MapFirmDataEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api").RequireAuthorization();

        // GET /api/consultants — full rows scoped by JWT prodkey
        grp.MapGet("/consultants", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from consultant where prodkey = @pk and isdeleted = false order by name";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListConsultants");

        // GET /api/groups — full rows scoped by JWT prodkey
        grp.MapGet("/groups", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from groups where prodkey = @pk and isdeleted = false order by groupname";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListGroups");
    }
}
