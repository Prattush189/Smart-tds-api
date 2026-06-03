namespace SmartTdsApi.Data;

/// <summary>Bound from the "Db" config section. Env vars override, e.g. Db__Password.</summary>
public sealed class DbOptions
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 5432;
    public string Username { get; set; } = "postgres";
    public string Password { get; set; } = "";
    public string MasterDatabase { get; set; } = "masterdbtds";
    /// <summary>e.g. "smarttds{0}" -> smarttds26 for year "26".</summary>
    public string YearDatabaseTemplate { get; set; } = "smarttds{0}";
}
