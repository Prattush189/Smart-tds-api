namespace SmartTdsApi.Auth;

public sealed class JwtOptions
{
    public string Issuer { get; set; } = "SmartTdsApi";
    public string Audience { get; set; } = "SmartTdsClient";
    public string Key { get; set; } = "";
    public int ExpiryMinutes { get; set; } = 480;
}
