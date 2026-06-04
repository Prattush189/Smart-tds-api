using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartTdsApi.Auth;
using SmartTdsApi.Data;
using SmartTdsApi.Endpoints;

var builder = WebApplication.CreateBuilder(args);

// ---- LOCAL MODE: allow running as a Windows Service (no-op on Linux/console).
// When launched by Windows SCM, this also fixes ContentRoot to the install dir
// so appsettings*.json resolve. On the Linux VPS (systemd) this does nothing. ----
builder.Host.UseWindowsService();

// ---- Options (env vars override, e.g. Db__Password, Jwt__Key) ----
builder.Services.Configure<DbOptions>(builder.Configuration.GetSection("Db"));
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

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

// ---- SECURITY: rate limiting (deadline-storm + brute-force protection) ----
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    // global per-client fixed window
    o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ctx.Connection.RemoteIpAddress?.ToString() ?? "anon",
            factory: _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 }));
    // strict limiter for login (brute-force)
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
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "ok", utc = DateTime.UtcNow })).AllowAnonymous();

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
app.MapTdsEntryEndpoints();
app.MapBackupEndpoints();

// Local mode: self-apply any pending schema migrations on startup (idempotent).
SmartTdsApi.Endpoints.BackupEndpoints.RunMigrationsOnStartup(app.Services);

app.Run();
