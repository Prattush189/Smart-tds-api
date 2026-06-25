namespace SmartTdsApi.Data;

/// <summary>Bound from the "Db" config section. Env vars override, e.g. Db__Password.</summary>
public sealed class DbOptions
{
    /// <summary>
    /// FIXED local DB password, identical on every STANDALONE LOCAL install (see
    /// provision-local.ps1, which sets the smarttds_app role + postgres superuser to this).
    /// In Local mode the API hardcodes this (Program.cs PostConfigure) instead of trusting
    /// appsettings.Local.json — so an MSI upgrade that preserves an old/patched appsettings,
    /// or a failed config patch, can NEVER make the API send a stale password (the recurring
    /// "28P01 / master:null"). Online/cloud is UNAFFECTED — it uses the real secret from env
    /// vars / appsettings. Acceptable because local PG only listens on 127.0.0.1 and
    /// smarttds_app is least-privilege.
    /// </summary>
    public const string LocalPassword = "Pass@123";

    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 5432;
    public string Username { get; set; } = "postgres";
    public string Password { get; set; } = "";
    public string MasterDatabase { get; set; } = "masterdbtds";
    /// <summary>e.g. "smarttds{0}" -> smarttds26 for year "26".</summary>
    public string YearDatabaseTemplate { get; set; } = "smarttds{0}";
}
