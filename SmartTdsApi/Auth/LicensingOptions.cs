namespace SmartTdsApi.Auth;

/// <summary>
/// Bound from the "Licensing" config section. Drives the deployment mode and the
/// legacy smartbizin ServiceUL.svc licence validation.
/// </summary>
public sealed class LicensingOptions
{
    /// <summary>Online = our cloud (user + seat auth). Local = a LAN server (user auth, NO seat cap).</summary>
    public string Mode { get; set; } = "Online";

    /// <summary>ServiceUL.svc endpoints tried in order (primary, then fallback).</summary>
    public string[] ServiceUrls { get; set; } =
    {
        "http://www.smartbizin.com/checking/ServiceUL.svc",
        "http://www.smartbizindia.com/checking/ServiceUL.svc"
    };

    /// <summary>ServiceUL credentials (legacy: pwd "Hello.123", product "stdsN").</summary>
    public string Auth { get; set; } = "Hello.123";
    public string ProductName { get; set; } = "stdsN";
    public string LicenceType { get; set; } = "Paid";   // Paid | Demo

    /// <summary>How long a successful ServiceUL result is cached before re-validating.</summary>
    public int RecheckHours { get; set; } = 24;

    /// <summary>Days a previously-validated licence keeps working when ServiceUL is
    /// unreachable (the legacy Pump.cs offline window, persisted in applicationparams.auth).</summary>
    public int GraceDays { get; set; } = 5;

    /// <summary>Override the persisted machine-id file path (default: ProgramData\SmartTds\machineid.dat).</summary>
    public string? MachineIdFile { get; set; }

    public bool IsLocal  => string.Equals(Mode, "Local", StringComparison.OrdinalIgnoreCase);
    public bool IsOnline => !IsLocal;
}

/// <summary>Outcome of a ServiceUL licence check.</summary>
public sealed record LicenceResult(
    bool Allowed, string Status, DateTime? Expiry, string RegisteredTo, string Message, DateTime CheckedUtc)
{
    public static LicenceResult Fail(string message) =>
        new(false, "Error", null, "", message, DateTime.UtcNow);
}
