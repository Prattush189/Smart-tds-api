using System.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using Npgsql;

namespace SmartTdsApi.Data;

public sealed class DbConnectionFactory : IDbConnectionFactory
{
    private readonly DbOptions _opt;
    private readonly IHttpContextAccessor _http;

    public DbConnectionFactory(IOptions<DbOptions> opt, IHttpContextAccessor http)
    {
        _opt = opt.Value;
        _http = http;
    }

    public Task<IDbConnection> OpenMasterAsync(CancellationToken ct = default)
        => OpenAsync(_opt.MasterDatabase, ct);

    public async Task<IDbConnection> OpenYearAsync(string year, CancellationToken ct = default)
    {
        var db = string.Format(_opt.YearDatabaseTemplate, NormalizeYear(year));
        var conn = (NpgsqlConnection)await OpenAsync(db, ct);   // also sets app.prodkey

        // Year tables have no prodkey column, so RLS there keys on app.subcodes — the
        // CSV of this firm's assessee subcodes (fetched from master, which is itself
        // prodkey-scoped by RLS). Set per request; unset -> year RLS default-deny.
        var prodkey = CurrentProdkey();
        if (!string.IsNullOrEmpty(prodkey))
        {
            var csv = await OwnedSubcodesCsvAsync(prodkey, ct);
            using var cmd = new NpgsqlCommand("select set_config('app.subcodes', @s, false)", conn);
            cmd.Parameters.AddWithValue("s", csv);
            await cmd.ExecuteNonQueryAsync(ct);
        }
        return conn;
    }

    private string CurrentProdkey() => _http.HttpContext?.User?.FindFirst("prodkey")?.Value ?? "";

    // The firm's assessee subcodes as a CSV (for app.subcodes). A no-cache master
    // query per year-connection open — cheap at this scale; always fresh so a newly
    // added assessee is immediately usable. (Add a short cache if year screens get chatty.)
    private async Task<string> OwnedSubcodesCsvAsync(string prodkey, CancellationToken ct)
    {
        using var master = (NpgsqlConnection)await OpenAsync(_opt.MasterDatabase, ct);  // sets app.prodkey -> assessee scoped
        using var cmd = new NpgsqlCommand(
            "select string_agg(subcode::text, ',') from assessee where prodkey = @p", master);
        cmd.Parameters.AddWithValue("p", prodkey);
        return (await cmd.ExecuteScalarAsync(ct)) as string ?? "";
    }

    private async Task<IDbConnection> OpenAsync(string database, CancellationToken ct)
    {
        var csb = new NpgsqlConnectionStringBuilder
        {
            Host = _opt.Host,
            Port = _opt.Port,
            Username = _opt.Username,
            Password = _opt.Password,
            Database = database,
            Pooling = true,          // Npgsql pools per connection string (per DB)
            MaxPoolSize = 20
        };
        var conn = new NpgsqlConnection(csb.ConnectionString);
        await conn.OpenAsync(ct);

        // RLS tenant: set app.prodkey from the JWT on EVERY connection. Because the
        // factory always sets it, a pooled physical connection can never carry a stale
        // tenant from a previous request. Unset/empty -> RLS default-deny (no rows).
        var prodkey = CurrentProdkey();
        using (var cmd = new NpgsqlCommand("select set_config('app.prodkey', @p, false)", conn))
        {
            cmd.Parameters.AddWithValue("p", prodkey);
            await cmd.ExecuteNonQueryAsync(ct);
        }
        return conn;
    }

    /// <summary>"26", "2026", "smarttds26" -> "26". Guards against injection into the DB name.</summary>
    private static string NormalizeYear(string year)
    {
        var digits = new string((year ?? "").Where(char.IsDigit).ToArray());
        if (digits.Length == 4) digits = digits.Substring(2); // 2026 -> 26
        if (digits.Length != 2)
            throw new ArgumentException($"Invalid assessment year '{year}'. Expected 2-digit like '26'.");
        return digits;
    }
}
