using System.Diagnostics;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SmartTdsApi.Auth;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Bound from the "Backup" config section. Drives the local pg_dump/pg_restore
/// backup feature. All have safe defaults matching provision-local.ps1.
/// </summary>
public sealed class BackupOptions
{
    /// <summary>Folder holding backup-local.ps1 / restore-local.ps1.</summary>
    public string? ScriptsDir { get; set; }
    public string? PgBin { get; set; }
    public string? BackupRoot { get; set; }
    public int Port { get; set; } = 5433;
    public string SuperUser { get; set; } = "postgres";
    public string SuperPwd { get; set; } = "Pass@123";
    public int Keep { get; set; } = 30;

    public string ResolvedScriptsDir =>
        ScriptsDir ?? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "_migration", "local"));
    public string ResolvedBackupRoot =>
        BackupRoot ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "SmartTds", "backups");
    // pgsql ships alongside the API under the install dir (…\api → …\pgsql\bin),
    // NOT under ProgramData — resolve it relative to the API exe.
    public string ResolvedPgBin =>
        PgBin ?? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "pgsql", "bin"));
}

/// <summary>
/// Local-mode backup/restore over pg_dump -Fc. Disabled in Online mode (the shared
/// cloud cluster is backed up server-side, not per-firm). Admin only.
/// </summary>
public static class BackupEndpoints
{
    public static void MapBackupEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/backups").RequireAuthorization();

        // POST /api/backups — take a new backup now
        grp.MapPost("", async (ClaimsPrincipal user, IOptions<LicensingOptions> lic,
                               IOptions<BackupOptions> opt, CancellationToken ct) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!IsAdmin(user)) return Results.Forbid();
            var o = opt.Value;
            var (code, stdout, stderr) = await RunScript(o, "backup-local.ps1",
                new[] { "-Label", "manual", "-Keep", o.Keep.ToString() }, ct);
            if (code != 0) return Results.Problem("Backup failed: " + Tail(stderr + stdout), statusCode: 500);
            var zip = LastLine(stdout);
            var fi = (zip is not null && File.Exists(zip)) ? new FileInfo(zip) : null;
            return Results.Ok(new
            {
                ok = true,
                fileName = fi?.Name ?? Path.GetFileName(zip ?? ""),
                sizeBytes = fi?.Length ?? 0,
                createdUtc = fi?.LastWriteTimeUtc
            });
        }).WithName("CreateBackup");

        // GET /api/backups — list existing backups
        grp.MapGet("", (ClaimsPrincipal user, IOptions<LicensingOptions> lic, IOptions<BackupOptions> opt) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!IsAdmin(user)) return Results.Forbid();
            var dir = opt.Value.ResolvedBackupRoot;
            if (!Directory.Exists(dir)) return Results.Ok(Array.Empty<object>());
            var list = new DirectoryInfo(dir).GetFiles("SmartTdsBackup_*.zip")
                .OrderByDescending(f => f.LastWriteTimeUtc)
                .Select(f => new { fileName = f.Name, sizeBytes = f.Length, createdUtc = f.LastWriteTimeUtc });
            return Results.Ok(list);
        }).WithName("ListBackups");

        // GET /api/backups/{file} — download a backup zip
        grp.MapGet("/{file}", (string file, ClaimsPrincipal user,
                               IOptions<LicensingOptions> lic, IOptions<BackupOptions> opt) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!IsAdmin(user)) return Results.Forbid();
            var path = SafeBackupPath(opt.Value.ResolvedBackupRoot, file);
            if (path is null || !File.Exists(path)) return Results.NotFound();
            return Results.File(path, "application/zip", Path.GetFileName(path));
        }).WithName("DownloadBackup");

        // POST /api/backups/{file}/restore — restore from an existing backup zip.
        // restore-local.ps1 STOPS and STARTS the API service, so it must NOT run inside
        // this request (it would kill its own host mid-restore). We launch it DETACHED
        // via a one-shot Scheduled Task (runs as SYSTEM, independent of the API process)
        // and return immediately; the client then waits for the API to come back.
        grp.MapPost("/{file}/restore", (string file, ClaimsPrincipal user,
                               IOptions<LicensingOptions> lic, IOptions<BackupOptions> opt) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!IsAdmin(user)) return Results.Forbid();
            var o = opt.Value;
            var path = SafeBackupPath(o.ResolvedBackupRoot, file);
            if (path is null || !File.Exists(path)) return Results.NotFound();

            // write a wrapper .cmd (avoids schtasks nested-quote pain), then run it as a
            // detached one-shot SYSTEM task.
            var script = Path.Combine(o.ResolvedScriptsDir, "restore-local.ps1");
            var wrapper = Path.Combine(o.ResolvedBackupRoot, "_restore-run.cmd");
            File.WriteAllText(wrapper,
                "@echo off\r\n" +
                $"powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"{script}\" " +
                $"-BackupZip \"{path}\" -PgBin \"{o.ResolvedPgBin}\" -Port {o.Port} " +
                $"-SuperUser {o.SuperUser} -SuperPwd {o.SuperPwd} -Force\r\n");

            RunQuick("schtasks.exe", $"/Create /TN SmartTdsRestore /TR \"{wrapper}\" /SC ONCE /ST 23:59 /RU SYSTEM /RL HIGHEST /F");
            RunQuick("schtasks.exe", "/Run /TN SmartTdsRestore");

            return Results.Json(new
            {
                ok = true,
                restored = Path.GetFileName(path),
                message = "Restore started. The server will restart in a moment — please reopen SmartTds shortly."
            }, statusCode: 202);
        }).WithName("RestoreBackup");

        // POST /api/migrate — apply pending schema migrations (Local only). ADMIN only:
        // it runs migrate-local.ps1 as the postgres superuser, so it must not be triggerable
        // by a normal user. Idempotent. The desktop calls this after SmartUpdater has fetched
        // new migration files, so locals self-update without a reinstall.
        app.MapPost("/api/migrate", async (ClaimsPrincipal user, IOptions<LicensingOptions> lic, IOptions<BackupOptions> opt, CancellationToken ct) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!IsAdmin(user)) return Results.Forbid();
            var (code, stdout, stderr) = await RunScript(opt.Value, "migrate-local.ps1", Array.Empty<string>(), ct);
            if (code != 0) return Results.Problem("Migrate failed: " + Tail(stderr + stdout), statusCode: 500);
            return Results.Ok(new { ok = true, output = Tail(stdout, 1000) });
        }).RequireAuthorization().WithName("RunMigrations");
    }

    /// <summary>Fire-and-forget: apply pending migrations at API startup (Local mode).
    /// Self-heals after SmartUpdater drops new files and the service restarts.</summary>
    public static void RunMigrationsOnStartup(IServiceProvider sp)
    {
        var lic = sp.GetRequiredService<IOptions<LicensingOptions>>().Value;
        if (!lic.IsLocal) return;
        var opt = sp.GetRequiredService<IOptions<BackupOptions>>().Value;
        var log = sp.GetService<ILoggerFactory>()?.CreateLogger("Migrations");
        _ = Task.Run(async () =>
        {
            try
            {
                var (code, so, se) = await RunScript(opt, "migrate-local.ps1", Array.Empty<string>(), CancellationToken.None);
                if (code != 0) log?.LogError("Startup migrations failed: {Err}", Tail(se + so));
                else log?.LogInformation("Startup migrations ok: {Out}", Tail(so, 400));
            }
            catch (Exception ex) { log?.LogError(ex, "Startup migrations threw"); }
        });
    }

    private static IResult OnlineNotSupported() =>
        Results.Problem("Backups are managed server-side in Online mode.", statusCode: 400);

    private static bool IsAdmin(ClaimsPrincipal user) =>
        string.Equals(user.FindFirstValue("usertype"), "ADMIN", StringComparison.OrdinalIgnoreCase);

    // fire a short-lived helper (schtasks) and wait briefly; used to launch the
    // detached restore task. Best-effort: never throws into the request.
    private static void RunQuick(string exe, string args)
    {
        try
        {
            var psi = new ProcessStartInfo(exe)
            {
                Arguments = args,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            using var p = Process.Start(psi);
            p?.WaitForExit(15000);
        }
        catch { /* ignore — restore task creation is best-effort */ }
    }

    // resolve a user-supplied file name strictly inside BackupRoot (no traversal)
    private static string? SafeBackupPath(string root, string file)
    {
        var name = Path.GetFileName(file);
        if (string.IsNullOrEmpty(name) || name != file) return null;
        if (!name.StartsWith("SmartTdsBackup_") || !name.EndsWith(".zip")) return null;
        return Path.Combine(root, name);
    }

    private static async Task<(int code, string stdout, string stderr)> RunScript(
        BackupOptions o, string script, string[] extra, CancellationToken ct)
    {
        var scriptPath = Path.Combine(o.ResolvedScriptsDir, script);
        var args = new List<string>
        {
            "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", scriptPath,
            "-Port", o.Port.ToString(), "-SuperUser", o.SuperUser, "-SuperPwd", o.SuperPwd
        };
        args.Add("-PgBin"); args.Add(o.ResolvedPgBin);   // always: pgsql is under the app dir, not ProgramData
        if (!string.IsNullOrEmpty(o.BackupRoot)) { args.Add("-BackupRoot"); args.Add(o.BackupRoot!); }
        args.AddRange(extra);

        var psi = new ProcessStartInfo("powershell.exe")
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        foreach (var a in args) psi.ArgumentList.Add(a);

        using var p = new Process { StartInfo = psi };
        var so = new StringBuilder();
        var se = new StringBuilder();
        p.OutputDataReceived += (_, e) => { if (e.Data != null) so.AppendLine(e.Data); };
        p.ErrorDataReceived  += (_, e) => { if (e.Data != null) se.AppendLine(e.Data); };
        p.Start();
        p.BeginOutputReadLine();
        p.BeginErrorReadLine();
        await p.WaitForExitAsync(ct);
        return (p.ExitCode, so.ToString(), se.ToString());
    }

    private static string? LastLine(string s) =>
        s.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries) is { Length: > 0 } lines
            ? lines[^1] : null;

    private static string Tail(string s, int max = 600) =>
        s.Length <= max ? s : s[^max..];
}
