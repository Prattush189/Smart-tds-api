using System.Data;

namespace SmartTdsApi.Data;

/// <summary>
/// Opens connections to either the shared master DB or a per-assessment-year DB.
/// This is the API equivalent of the legacy global-mutable DbVariables.DbName switch,
/// but stateless and per-request: the YEAR is the routing key, never a tenant.
/// </summary>
public interface IDbConnectionFactory
{
    Task<IDbConnection> OpenMasterAsync(CancellationToken ct = default);
    Task<IDbConnection> OpenYearAsync(string year, CancellationToken ct = default);
}
