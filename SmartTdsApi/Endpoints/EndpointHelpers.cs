using System.Security.Claims;
using Npgsql;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Shared scaffolding for the minimal-API endpoint classes, so each endpoint
/// body is just its SQL + result shaping:
///  - Prodkey():  JWT firm claim, null when missing (caller returns 401)
///  - IsAdmin():  usertype=ADMIN claim gate
///  - TryYear():  X-Assessment-Year header check with the standard 400
///  - InYear():   year-DB call with the standard error mapping
///                (bad year string -> 400, DB not provisioned (3D000) -> 404)
///  - Write():    master-DB write with the standard "Could not save X" 400
/// </summary>
internal static class Api
{
    public const string YearHeader = "X-Assessment-Year";

    /// <summary>Prodkey (firm id) from the JWT, or null when missing/empty.</summary>
    public static string? Prodkey(ClaimsPrincipal principal)
    {
        var pk = principal.FindFirst("prodkey")?.Value;
        return string.IsNullOrEmpty(pk) ? null : pk;
    }

    /// <summary>ADMIN gate: usertype claim issued at login.</summary>
    public static bool IsAdmin(ClaimsPrincipal user) =>
        string.Equals(user.FindFirstValue("usertype"), "ADMIN", StringComparison.OrdinalIgnoreCase);

    /// <summary>X-Assessment-Year header; on false, <paramref name="bad"/> is the standard 400.</summary>
    public static bool TryYear(HttpRequest http, out string year, out IResult bad)
    {
        if (!http.Headers.TryGetValue(YearHeader, out var v) || string.IsNullOrWhiteSpace(v))
        {
            year = null!;
            bad = Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });
            return false;
        }
        year = v!;
        bad = null!;
        return true;
    }

    /// <summary>
    /// Runs a year-DB endpoint body with the standard error mapping:
    /// ArgumentException (bad year string) -> 400; PostgresException 3D000
    /// (smarttds&lt;YY&gt; database missing) -> 404. Everything else bubbles to the
    /// global exception handler (500, logged, no stack-trace leak).
    /// </summary>
    public static async Task<IResult> InYear(string year, Func<Task<IResult>> action)
    {
        try
        {
            return await action();
        }
        catch (ArgumentException ex)
        {
            return Results.BadRequest(new { error = ex.Message });
        }
        catch (PostgresException pe) when (pe.SqlState == "3D000") // invalid_catalog_name
        {
            return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
        }
    }

    /// <summary>
    /// Runs a write endpoint body mapping any failure to a 400 whose message the
    /// desktop shows verbatim: "{failPrefix}: &lt;db message&gt; [column: c] — detail".
    /// </summary>
    public static async Task<IResult> Write(string failPrefix, Func<Task<IResult>> action)
    {
        try
        {
            return await action();
        }
        catch (PostgresException pe)
        {
            return Results.BadRequest(new { error = PgError(failPrefix, pe) });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { error = failPrefix + ": " + ex.Message });
        }
    }

    /// <summary>Formats a PostgresException the way every save endpoint reports it.</summary>
    public static string PgError(string failPrefix, PostgresException pe) =>
        failPrefix + ": " + pe.MessageText
        + (string.IsNullOrEmpty(pe.ColumnName) ? "" : " [column: " + pe.ColumnName + "]")
        + (string.IsNullOrEmpty(pe.Detail) ? "" : " — " + pe.Detail);
}
