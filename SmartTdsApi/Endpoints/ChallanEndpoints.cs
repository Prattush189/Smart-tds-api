using Dapper;
using Npgsql;
using SmartTdsApi.Data;
using SmartTdsApi.Models;

namespace SmartTdsApi.Endpoints;

public static class ChallanEndpoints
{
    public const string YearHeader = "X-Assessment-Year";

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
                var sql = @"select id, ayid, subcode, challandt, challanno,
                                   totaltds, tax, total, formtype
                            from addchallan
                            where subcode = @subCode
                            order by id";
                var rows = await conn.QueryAsync<ChallanDto>(
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
    }
}
