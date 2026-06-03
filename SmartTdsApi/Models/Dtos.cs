namespace SmartTdsApi.Models;

public sealed record LoginRequest(string Username, string Password, string? ProdKey, string? Machine);

public sealed record LoginResponse(
    string Token, DateTime ExpiresUtc, string Name, string UserType,
    string RegisteredTo, string LicenceType, DateTime LicenceExpiry, int SeatsUsed, int MaxSeats,
    UserInfo User);

/// <summary>Full user record the desktop maps to MasterEntities.User (drives permissions).</summary>
public sealed record UserInfo(
    int UserId, string Username, string Name, string UserType, string ProdKey,
    string EmailId, string Mobile,
    bool AssesseeAddFlag, bool AssesseeEditFlag, bool AssesseeDeleteFlag,
    bool ViewPwdFlag, bool BackupFlag, bool RestoreFlag, bool EfilingFlag,
    bool RptViewFlag, bool EditFiledReturnFlag, int? SelectedPer);

/// <summary>Slim list/detail projection of masterdbtds.assessee (shared master data).</summary>
public sealed record AssesseeDto
{
    public int SubCode { get; init; }
    public string? TradeName { get; init; }
    public string? FirstName { get; init; }
    public string? LastName { get; init; }
    public string? Pan { get; init; }
    public string? AssesseeStatus { get; init; }
    public string? MobilePrimary { get; init; }
    public string? EmailPrimary { get; init; }
}

/// <summary>Projection of smarttds&lt;year&gt;.addchallan (per-year routed data).</summary>
public sealed record ChallanDto
{
    public int Id { get; init; }
    public int AyId { get; init; }
    public int SubCode { get; init; }
    public string? ChallanDt { get; init; }
    public string? ChallanNo { get; init; }
    public decimal? TotalTds { get; init; }
    public decimal? Tax { get; init; }
    public decimal? Total { get; init; }
    public string? FormType { get; init; }
}
