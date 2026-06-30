using System.Net;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartTdsApi.Auth;
using SmartTdsApi.Data;
using SmartTdsApi.Endpoints;
using SmartTdsApi.Json;

var builder = WebApplication.CreateBuilder(args);

// ---- LOCAL MODE: allow running as a Windows Service (no-op on Linux/console).
// When launched by Windows SCM, this also fixes ContentRoot to the install dir
// so appsettings*.json resolve. On the Linux VPS (systemd) this does nothing. ----
builder.Host.UseWindowsService();

// ---- Support file log: every Warning+ (incl. the unhandled-exception handler's
// full stack traces) also lands in a daily file the user can just send us. It lives
// NEXT TO the app (…\api -> …\Data\logs), same drive the firm installed to — NOT on
// C:\ProgramData — so the whole SmartTds data set stays off the Windows drive and honours
// installs on a non-C: drive (same folder as the install log). Linux VPS: <app>/logs.
var supportLogDir = OperatingSystem.IsWindows()
    ? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "Data", "logs"))
    : Path.Combine(AppContext.BaseDirectory, "logs");
builder.Logging.AddProvider(new SmartTdsApi.Logging.FileLoggerProvider(supportLogDir));

// ---- Options (env vars override, e.g. Db__Password, Jwt__Key) ----
builder.Services.Configure<DbOptions>(builder.Configuration.GetSection("Db"));
// LOCAL mode: the DB password is a FIXED constant baked into every install. Hardcode it here
// (after binding) so the API never depends on appsettings.Local.json for it — this is the
// permanent cure for the role<->file password drift. Online/cloud keeps its real secret.
if (builder.Environment.IsEnvironment("Local"))
    builder.Services.PostConfigure<DbOptions>(o => o.Password = DbOptions.LocalPassword);
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

builder.Services.AddHttpContextAccessor();   // lets DbConnectionFactory read the JWT prodkey for RLS
builder.Services.AddMemoryCache();           // caches per-firm subcodes for year-DB RLS (perf)
builder.Services.AddSingleton<IDbConnectionFactory, DbConnectionFactory>();
builder.Services.AddSingleton<JwtTokenService>();

// Licensing: licence keys are validated against the legacy smartbizin ServiceUL.svc
// (Online = cloud + seat cap; Local = LAN server + unlimited seats). HttpClient does
// the outbound SOAP call; LicenceService caches results + holds this server's machine-id.
builder.Services.Configure<LicensingOptions>(builder.Configuration.GetSection("Licensing"));
builder.Services.AddHttpClient();
builder.Services.AddSingleton<LicenceService>();

// Local-mode pg_dump/pg_restore backup feature (no-op binding in Online mode).
builder.Services.Configure<SmartTdsApi.Endpoints.BackupOptions>(builder.Configuration.GetSection("Backup"));

// Vendor support registry. Endpoint is OFF unless Support:Key is set (only the central VPS sets it).
builder.Services.Configure<SmartTdsApi.Endpoints.SupportOptions>(builder.Configuration.GetSection("Support"));

// ---- Tolerant JSON body-binding for the legacy desktop client ----
// The WinForms app (Newtonsoft, loose typing) sends e.g. "DirFlag":"false" (string, not bool),
// "" for absent numbers, and quoted numbers. System.Text.Json is strict and 400s on those with
// an empty body (which the desktop surfaces as "Import failed:" with no detail). Accept the loose
// shapes on input; responses stay canonical. Covers payee, tdsentry, challan and every DTO.
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.NumberHandling = JsonNumberHandling.AllowReadingFromString;
    o.SerializerOptions.Converters.Add(new TolerantBooleanConverter());
    o.SerializerOptions.Converters.Add(new TolerantNullableBooleanConverter());
    o.SerializerOptions.Converters.Add(new TolerantNullableInt32Converter());
    o.SerializerOptions.Converters.Add(new TolerantNullableInt64Converter());
    o.SerializerOptions.Converters.Add(new TolerantNullableDecimalConverter());
    o.SerializerOptions.Converters.Add(new TolerantNullableDoubleConverter());
    o.SerializerOptions.Converters.Add(new TolerantInt32Converter());
    o.SerializerOptions.Converters.Add(new TolerantInt64Converter());
    o.SerializerOptions.Converters.Add(new TolerantDecimalConverter());
    o.SerializerOptions.Converters.Add(new TolerantDoubleConverter());
    o.SerializerOptions.Converters.Add(new TolerantStringConverter());
    o.SerializerOptions.Converters.Add(new TolerantDateTimeConverter());
    o.SerializerOptions.Converters.Add(new TolerantNullableDateTimeConverter());
});

var jwt = builder.Configuration.GetSection("Jwt").Get<JwtOptions>()!;

// ---- SECURITY: fail fast on a weak/default signing key outside Development ----
if (!builder.Environment.IsDevelopment())
{
    if (string.IsNullOrWhiteSpace(jwt.Key) || jwt.Key.Length < 32 || jwt.Key.Contains("dev-only"))
        throw new InvalidOperationException(
            "Jwt:Key must be a strong (>=32 char) secret in non-Development environments. Set Jwt__Key via env/secret store.");
}

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key))
        };
    });
builder.Services.AddAuthorization();

// ---- Behind nginx (Online) Kestrel only binds 127.0.0.1, so the reverse proxy is the
// ONLY ingress. Honor X-Forwarded-For so RemoteIpAddress is the REAL client IP; otherwise
// every online client looks like 127.0.0.1 and shares one rate-limit bucket (the bug that
// broke bulk import + could lock out logins). Loopback-only bind makes trusting the header
// safe — external clients can't reach Kestrel directly to spoof it. No-op if nginx omits XFF. ----
builder.Services.Configure<ForwardedHeadersOptions>(o =>
{
    o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    o.KnownProxies.Add(IPAddress.Loopback);
    o.KnownProxies.Add(IPAddress.IPv6Loopback);
});

// ---- SECURITY: rate limiting (deadline-storm + brute-force protection) ----
// UseRateLimiter is placed AFTER UseAuthentication (below), so ctx.User is populated here
// and the global limiter can partition by the authenticated firm instead of raw IP.
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    // Per-request partition: an AUTHENTICATED caller gets a generous per-firm window so
    // legitimate bulk work (Excel import = hundreds of small writes) is never throttled,
    // and one firm's burst can't starve another. ANONYMOUS traffic (health, pre-login)
    // stays on a tight per-IP window.
    o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(ctx =>
    {
        var firm = ctx.User?.FindFirst("prodkey")?.Value;
        if (!string.IsNullOrEmpty(firm))
            return RateLimitPartition.GetFixedWindowLimiter("firm:" + firm,
                _ => new FixedWindowRateLimiterOptions { PermitLimit = 2000, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 });

        var ip = ctx.Connection.RemoteIpAddress?.ToString() ?? "anon";
        return RateLimitPartition.GetFixedWindowLimiter("ip:" + ip,
            _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 });
    });
    // strict limiter for login (brute-force) — per real client IP (X-Forwarded-For honored)
    o.AddPolicy("login", ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ctx.Connection.RemoteIpAddress?.ToString() ?? "anon",
            factory: _ => new FixedWindowRateLimiterOptions { PermitLimit = 8, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});

// ---- CORS: deny by default; allow only configured origins (Cors:Origins) ----
var corsOrigins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
{
    if (corsOrigins.Length > 0) p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod();
}));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "SmartTds API", Version = "v1" });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization", Type = SecuritySchemeType.Http, Scheme = "bearer",
        BearerFormat = "JWT", In = ParameterLocation.Header,
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

var app = builder.Build();

// Must run before anything that reads the client IP (rate limiter, error logs).
app.UseForwardedHeaders();

// ---- SECURITY: clean problem-details on unhandled errors (no stack-trace leak) ----
app.UseExceptionHandler(eh => eh.Run(async ctx =>
{
    var ex = ctx.Features.Get<IExceptionHandlerFeature>()?.Error;
    app.Logger.LogError(ex, "Unhandled exception on {Path}", ctx.Request.Path);
    ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
    ctx.Response.ContentType = "application/json";
    await ctx.Response.WriteAsJsonAsync(new { error = "An unexpected error occurred." });
}));

// ---- SECURITY: response headers ----
app.Use(async (ctx, next) =>
{
    var h = ctx.Response.Headers;
    h["X-Content-Type-Options"] = "nosniff";
    h["X-Frame-Options"] = "DENY";
    h["Referrer-Policy"] = "no-referrer";
    await next();
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartTds API v1"));
}

app.UseCors();
app.UseAuthentication();   // populate ctx.User BEFORE the limiter so it can partition per-firm
app.UseRateLimiter();
app.UseAuthorization();

// Health + LAN-discovery probe. Opens a connection to the master DB and reports its name,
// so the desktop's server scan can tell a REAL Smart TDS server (backed by masterdbtds)
// from any other service answering on :5080. If the master DB is unreachable, `master`
// comes back null and clients won't list this host.
app.MapGet("/health", async (SmartTdsApi.Data.IDbConnectionFactory db, CancellationToken ct) =>
{
    string master = null;
    try
    {
        using var conn = await db.OpenMasterAsync(ct);
        master = conn.Database;   // = "masterdbtds" when the master DB is reachable
    }
    catch (Exception ex)
    {
        // Log WHY master is null — /health is the first thing checked when login fails, and a
        // silent catch left no trace of the real DB error (28P01 password drift / connection
        // refused / database missing). Now it lands in the api-<date>.log.
        app.Logger.LogWarning(ex, "Health check: master DB unreachable");
    }
    // `name` lets the desktop's Server list show a friendly machine name instead of a bare IP.
    // `version` lets a LAN client read the server's API version (it has no local \api to
    // inspect) so it can prompt the user to run the updater on the server machine.
    var version = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version?.ToString();
    // surface the startup-migration outcome so a failed/half-applied migration is visible
    // (otherwise the API silently serves a stale schema → unrelated-looking 500s downstream).
    var migrations = SmartTdsApi.Endpoints.BackupEndpoints.MigrationsStatus;
    return Results.Ok(new { status = "ok", master, name = Environment.MachineName, utc = DateTime.UtcNow, version, migrations });
}).AllowAnonymous();

app.MapAuthEndpoints();
app.MapAssesseeEndpoints();
app.MapChallanEndpoints();
app.MapMastersEndpoints();
app.MapFirmDataEndpoints();
app.MapAssesseeResStatusEndpoints();
app.MapTaxMasterWriteEndpoints();
app.MapAyMasterWriteEndpoints();
app.MapYearDataEndpoints();
app.MapCompIncomeEndpoints();
app.MapAdminEndpoints();
app.MapBillingEndpoints();
app.MapFilingStatusEndpoints();
app.MapTdsEntryExtraEndpoints();
app.MapTdsPayeeEndpoints();
app.MapSalaryChildEndpoints();
app.MapPayeeEndpoints();
app.MapSalaryEndpoints();
app.MapTracesRequestEndpoints();
app.MapTdsEntryEndpoints();
app.MapBackupEndpoints();
app.MapSupportEndpoints();

// Local mode: self-apply any pending schema migrations on startup (idempotent).
SmartTdsApi.Endpoints.BackupEndpoints.RunMigrationsOnStartup(app.Services);

app.Run();
