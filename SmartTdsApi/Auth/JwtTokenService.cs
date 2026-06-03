using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace SmartTdsApi.Auth;

public sealed class JwtTokenService
{
    private readonly JwtOptions _opt;
    public JwtTokenService(IOptions<JwtOptions> opt) => _opt = opt.Value;

    /// <summary>Token carries identity/firm (prodkey) + session id (jti), NOT the
    /// assessment year. Year is a per-request dimension (X-Assessment-Year header).
    /// The jti matches a row in `sessions` for central seat enforcement.</summary>
    public (string token, DateTime expires) Issue(
        string username, string prodkey, string name, string userType, Guid jti)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opt.Key));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddMinutes(_opt.ExpiryMinutes);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, username),
            new Claim("prodkey", prodkey),
            new Claim("name", name ?? ""),
            new Claim("usertype", userType ?? ""),
            new Claim(JwtRegisteredClaimNames.Jti, jti.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _opt.Issuer,
            audience: _opt.Audience,
            claims: claims,
            expires: expires,
            signingCredentials: creds);

        return (new JwtSecurityTokenHandler().WriteToken(token), expires);
    }
}
