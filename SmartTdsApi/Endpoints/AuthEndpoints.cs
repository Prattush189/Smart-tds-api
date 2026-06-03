using System.Security.Claims;
using Dapper;
using SmartTdsApi.Auth;
using SmartTdsApi.Data;
using SmartTdsApi.Models;

namespace SmartTdsApi.Endpoints;

public static class AuthEndpoints
{
    private sealed record UserRow(
        int Userid, string Prodkey, string Username, string Name, string Pwd, string Usertype,
        string Emailid, string Mobile,
        bool Assesseeaddflag, bool Assesseeeditflag, bool Assesseedeleteflag, bool Viewpwdflag,
        bool Backupflag, bool Restoreflag, bool Efilingflag, bool Rptviewflag, bool Editfiledreturnflag,
        int? Selectedper, bool Isdeleted);
    private sealed record LicenceRow(string Prodkey, string Registered_to, string Licence_type, DateTime Expiry_date, int Max_seats, bool Is_active);

    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        // ---- LOGIN: Gate 1 licence -> Gate 2 user -> Gate 3 seat ----
        app.MapPost("/api/auth/login", async (
            LoginRequest req, IDbConnectionFactory db, JwtTokenService jwt,
            ILoggerFactory lf, CancellationToken ct) =>
        {
            var log = lf.CreateLogger("Auth");
            if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.Password)
                || string.IsNullOrWhiteSpace(req.ProdKey))
                return Results.BadRequest(new { error = "username, password and licence key (prodKey) are required" });

            var prodkey = req.ProdKey.Trim().ToUpperInvariant();   // licence keys stored UPPER
            using var conn = await db.OpenMasterAsync(ct);

            // GATE 1 — licence
            var lic = await conn.QueryFirstOrDefaultAsync<LicenceRow>(new CommandDefinition(
                "select prodkey, registered_to, licence_type, expiry_date, max_seats, is_active from licences where prodkey=@prodkey",
                new { prodkey }, cancellationToken: ct));
            if (lic is null || !lic.Is_active)
            {
                log.LogWarning("Login DENIED (licence {Key} invalid)", prodkey);
                return Results.Json(new { error = "Invalid or inactive licence key." }, statusCode: StatusCodes.Status403Forbidden);
            }
            if (lic.Expiry_date.Date < DateTime.UtcNow.Date)
                return Results.Json(new { error = $"Licence expired on {lic.Expiry_date:dd MMM yyyy}. Please renew." },
                    statusCode: StatusCodes.Status403Forbidden);

            // GATE 2 — user (exact prodkey match)
            var user = await conn.QueryFirstOrDefaultAsync<UserRow>(new CommandDefinition(
                @"select userid, prodkey, username, name, pwd, usertype, emailid, mobile,
                         assesseeaddflag, assesseeeditflag, assesseedeleteflag, viewpwdflag,
                         backupflag, restoreflag, efilingflag, rptviewflag, editfiledreturnflag,
                         selectedper, isdeleted
                  from users
                  where username=@Username and prodkey=@prodkey and isdeleted=false limit 1",
                new { req.Username, prodkey }, cancellationToken: ct));
            if (user is null || !PasswordHasher.Verify(req.Password, user.Pwd))
            {
                log.LogWarning("Login FAILED for {User} on licence {Key}", req.Username, prodkey);
                return Results.Json(new { error = "invalid credentials" }, statusCode: StatusCodes.Status401Unauthorized);
            }

            // GATE 3 — seat limit. ONE seat per USER: drop this user's existing
            // session first (a re-login REPLACES it, never consumes another seat),
            // and purge expired. Then only DISTINCT other users count toward the cap.
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from sessions where expires_on < now() or (prodkey=@prodkey and username=@username)",
                new { prodkey, username = user.Username }, cancellationToken: ct));
            var active = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                "select count(*) from sessions where prodkey=@prodkey", new { prodkey }, cancellationToken: ct));
            if (active >= lic.Max_seats)
                return Results.Json(new { error = $"Seat limit reached ({lic.Max_seats} concurrent users). Another user must log out first." },
                    statusCode: StatusCodes.Status403Forbidden);

            // issue session + token
            var jti = Guid.NewGuid();
            var (token, expires) = jwt.Issue(user.Username, user.Prodkey, user.Name, user.Usertype, jti);
            await conn.ExecuteAsync(new CommandDefinition(
                @"insert into sessions (jti, prodkey, username, machine, expires_on)
                  values (@jti, @prodkey, @username, @machine, @expires)",
                new { jti, prodkey, username = user.Username, machine = req.Machine, expires }, cancellationToken: ct));

            log.LogInformation("Login OK {User} on {Key} (seat {Used}/{Max})", user.Username, prodkey, active + 1, lic.Max_seats);
            var info = new UserInfo(user.Userid, user.Username, user.Name, user.Usertype, user.Prodkey,
                user.Emailid, user.Mobile,
                user.Assesseeaddflag, user.Assesseeeditflag, user.Assesseedeleteflag, user.Viewpwdflag,
                user.Backupflag, user.Restoreflag, user.Efilingflag, user.Rptviewflag, user.Editfiledreturnflag,
                user.Selectedper);
            return Results.Ok(new LoginResponse(token, expires, user.Name, user.Usertype,
                lic.Registered_to, lic.Licence_type, lic.Expiry_date, active + 1, lic.Max_seats, info));
        })
        .WithName("Login").RequireRateLimiting("login").AllowAnonymous();

        // ---- LOGOUT: free the seat ----
        app.MapPost("/api/auth/logout", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var jtiStr = principal.FindFirstValue("jti");
            if (Guid.TryParse(jtiStr, out var jti))
            {
                using var conn = await db.OpenMasterAsync(ct);
                await conn.ExecuteAsync(new CommandDefinition("delete from sessions where jti=@jti", new { jti }, cancellationToken: ct));
            }
            return Results.Ok(new { status = "logged out" });
        }).WithName("Logout").RequireAuthorization();
    }
}
