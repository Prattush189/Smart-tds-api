using System.Security.Cryptography;
using System.Text;
using Dapper;
using Microsoft.Extensions.Options;
using SmartTdsApi.Auth;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Bound from the "Support" config section. Drives the vendor support registry. The endpoint
/// is DISABLED unless a non-empty <see cref="Key"/> is configured (so it is off by default and
/// only active on the central VPS where the vendor sets Support__Key).
/// </summary>
public sealed class SupportOptions
{
    /// <summary>Shared secret the local installer must present (header X-Support-Key). Empty = endpoint disabled.</summary>
    public string Key { get; set; } = "";
}

/// <summary>Body for POST /api/support/install — sent best-effort by install-local.ps1.</summary>
public sealed record InstallReg(
    string? machineId, string? machineName, int? dbPort,
    string? superUser, string? superPwd, string? appRoleUser, string? appRolePwd,
    string? appVersion);

/// <summary>
/// Central install registry (vendor support). A LOCAL Database.exe install POSTs its
/// PostgreSQL credentials + machine-id here so the vendor can recover them later for remote
/// support. Authenticated by a SHARED KEY (not a JWT — there is no logged-in user at install
/// time), so it is AllowAnonymous + key-checked + rate-limited. Credentials are AES-encrypted
/// at rest. There is intentionally NO read endpoint — the vendor reads the table directly on
/// the VPS, so one tenant can never pull another's creds.
/// </summary>
public static class SupportEndpoints
{
    public static void MapSupportEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/support/install", async (
            InstallReg body, HttpRequest http, IOptions<SupportOptions> sup,
            IOptions<JwtOptions> jwt, IDbConnectionFactory db, ILoggerFactory lf, CancellationToken ct) =>
        {
            var log = lf.CreateLogger("Support");
            var key = sup.Value.Key ?? "";
            // Disabled unless configured (off by default; only the VPS sets Support__Key).
            if (string.IsNullOrEmpty(key)) return Results.NotFound();

            // Constant-time shared-key check.
            http.Headers.TryGetValue("X-Support-Key", out var sent);
            var sentKey = sent.ToString();
            if (sentKey.Length == 0 || !CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(sentKey), Encoding.UTF8.GetBytes(key)))
                return Results.Unauthorized();

            if (string.IsNullOrWhiteSpace(body.machineId))
                return Results.BadRequest(new { error = "machineId is required" });

            var clientIp = http.HttpContext.Connection.RemoteIpAddress?.ToString();
            try
            {
                using var conn = await db.OpenMasterAsync(ct);
                await conn.ExecuteAsync(new CommandDefinition(
                    @"insert into install_registry
                          (machineid, machinename, dbport, superuser, superpwdenc, approleuser,
                           approlepwdenc, appversion, clientip, installedutc, lastseenutc)
                      values (@machineid, @machinename, @dbport, @superuser, @superpwdenc, @approleuser,
                              @approlepwdenc, @appversion, @clientip,
                              (now() at time zone 'utc'), (now() at time zone 'utc'))
                      on conflict (machineid) do update set
                          machinename=excluded.machinename, dbport=excluded.dbport,
                          superuser=excluded.superuser, superpwdenc=excluded.superpwdenc,
                          approleuser=excluded.approleuser, approlepwdenc=excluded.approlepwdenc,
                          appversion=excluded.appversion, clientip=excluded.clientip,
                          lastseenutc=(now() at time zone 'utc')",
                    new
                    {
                        machineid = body.machineId,
                        machinename = body.machineName,
                        dbport = body.dbPort,
                        superuser = body.superUser,
                        superpwdenc = SecretBox.Encrypt(body.superPwd, jwt.Value.Key),
                        approleuser = body.appRoleUser,
                        approlepwdenc = SecretBox.Encrypt(body.appRolePwd, jwt.Value.Key),
                        appversion = body.appVersion,
                        clientip = clientIp
                    }, cancellationToken: ct));
                log.LogInformation("Install registered for machine {Mid} ({Name})", body.machineId, body.machineName);
                return Results.Ok(new { ok = true });
            }
            catch (Exception ex)
            {
                log.LogWarning(ex, "install_registry upsert failed for {Mid}", body.machineId);
                return Results.Problem("registry write failed", statusCode: 500);
            }
        })
        .AllowAnonymous()
        .RequireRateLimiting("login")   // reuse the strict per-IP limiter — installs are rare
        .WithName("RegisterInstall");
    }
}
