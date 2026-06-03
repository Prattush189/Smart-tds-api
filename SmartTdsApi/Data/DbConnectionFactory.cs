using System.Data;
using Microsoft.Extensions.Options;
using Npgsql;

namespace SmartTdsApi.Data;

public sealed class DbConnectionFactory : IDbConnectionFactory
{
    private readonly DbOptions _opt;

    public DbConnectionFactory(IOptions<DbOptions> opt) => _opt = opt.Value;

    public Task<IDbConnection> OpenMasterAsync(CancellationToken ct = default)
        => OpenAsync(_opt.MasterDatabase, ct);

    public Task<IDbConnection> OpenYearAsync(string year, CancellationToken ct = default)
    {
        var db = string.Format(_opt.YearDatabaseTemplate, NormalizeYear(year));
        return OpenAsync(db, ct);
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
