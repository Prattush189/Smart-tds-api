using System.Security.Claims;
using Dapper;
using Microsoft.Extensions.Options;
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
    private sealed record SeatRow(int Max_seats, bool Is_active);

    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        // ---- LOGIN: Gate 1 licence (ServiceUL) -> Gate 2 user (DB) -> Gate 3 seat (Online only) ----
        app.MapPost("/api/auth/login", async (
            LoginRequest req, IOptions<LicensingOptions> licOpt, LicenceService licence,
            IDbConnectionFactory db, JwtTokenService jwt, ILoggerFactory lf, CancellationToken ct) =>
        {
            var log = lf.CreateLogger("Auth");
            var opt = licOpt.Value;

            if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.Password)
                || string.IsNullOrWhiteSpace(req.ProdKey))
                return Results.BadRequest(new { error = "username, password and licence key (prodKey) are required" });

            var prodkey = req.ProdKey.Trim().ToUpperInvariant();   // licence keys stored UPPER

            // GATE 1 — LICENCE via smartbizin ServiceUL.svc (both modes)
            var lic = await licence.ValidateAsync(prodkey, ct);
            if (!lic.Allowed)
            {
                log.LogWarning("Login DENIED (licence {Key}: {Msg})", prodkey, lic.Message);
                return Results.Json(new { error = lic.Message }, statusCode:
                    lic.Status == "Error" ? StatusCodes.Status503ServiceUnavailable : StatusCodes.Status403Forbidden);
            }

            using var conn = await db.OpenMasterAsync(ct);

            // GATE 2 — USER (username + exact prodkey + PBKDF2) — both modes
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

            // session bookkeeping: drop this user's prior session + purge expired (both modes).
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from sessions where expires_on < now() or (prodkey=@prodkey and username=@username)",
                new { prodkey, username = user.Username }, cancellationToken: ct));

            int seatsUsed, maxSeats;
            if (opt.IsOnline)
            {
                // GATE 3 — SEAT cap from the small cloud licences table (prodkey -> max_seats)
                var seat = await conn.QueryFirstOrDefaultAsync<SeatRow>(new CommandDefinition(
                    "select max_seats, is_active from licences where prodkey=@prodkey", new { prodkey }, cancellationToken: ct));
                if (seat is null)
                    return Results.Json(new { error = "Licence not provisioned for seats on this server. Contact support." },
                        statusCode: StatusCodes.Status403Forbidden);
                if (!seat.Is_active)
                    return Results.Json(new { error = "Licence is inactive. Contact support." },
                        statusCode: StatusCodes.Status403Forbidden);

                maxSeats = seat.Max_seats;
                var active = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                    "select count(*) from sessions where prodkey=@prodkey", new { prodkey }, cancellationToken: ct));
                if (active >= maxSeats)
                    return Results.Json(new { error = $"Seat limit reached ({maxSeats} concurrent users). Another user must log out first." },
                        statusCode: StatusCodes.Status403Forbidden);
                seatsUsed = active + 1;
            }
            else
            {
                // LOCAL (LAN server): unlimited seats
                maxSeats = 0;
                seatsUsed = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                    "select count(*) from sessions where prodkey=@prodkey", new { prodkey }, cancellationToken: ct)) + 1;
            }

            // issue session + token
            var jti = Guid.NewGuid();
            var (token, expires) = jwt.Issue(user.Username, user.Prodkey, user.Name, user.Usertype, jti);
            await conn.ExecuteAsync(new CommandDefinition(
                @"insert into sessions (jti, prodkey, username, machine, expires_on)
                  values (@jti, @prodkey, @username, @machine, @expires)",
                new { jti, prodkey, username = user.Username, machine = req.Machine, expires }, cancellationToken: ct));

            log.LogInformation("Login OK {User} on {Key} mode={Mode} (seat {Used}/{Max})",
                user.Username, prodkey, opt.Mode, seatsUsed, maxSeats == 0 ? "unlimited" : maxSeats.ToString());

            var info = new UserInfo(user.Userid, user.Username, user.Name, user.Usertype, user.Prodkey,
                user.Emailid, user.Mobile,
                user.Assesseeaddflag, user.Assesseeeditflag, user.Assesseedeleteflag, user.Viewpwdflag,
                user.Backupflag, user.Restoreflag, user.Efilingflag, user.Rptviewflag, user.Editfiledreturnflag,
                user.Selectedper);
            // RegisteredTo + expiry come from ServiceUL; expiry may be open-ended (use far date if unknown).
            var licExpiry = lic.Expiry ?? new DateTime(2099, 12, 31);
            return Results.Ok(new LoginResponse(token, expires, user.Name, user.Usertype,
                lic.RegisteredTo, opt.LicenceType, licExpiry, seatsUsed, maxSeats, info));
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
