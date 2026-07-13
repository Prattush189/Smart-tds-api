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
    // Backups live with the install's data, NOT under ProgramData/CommonApplicationData.
    // The data dir is co-located at <AppDir>\Data (the API exe is at <AppDir>\api, so
    // …\api → …\Data\backups). Resolve it relative to the API exe, matching ResolvedPgBin.
    // (Old installs/backups under C:\ProgramData\SmartTds\backups: set Backup:BackupRoot
    // in config to point there, or move the zips into <AppDir>\Data\backups.)
    public string ResolvedBackupRoot =>
        BackupRoot ?? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "Data", "backups"));
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
    /// <summary>Startup-migration outcome, surfaced by /health so a failed/half-applied
    /// migration is visible to operators instead of silently serving a stale schema.
    /// One of: "skipped" (online mode), "pending", "ok", "failed".</summary>
    public static volatile string MigrationsStatus = "pending";

    public static void MapBackupEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/backups").RequireAuthorization();

        // POST /api/backups — take a new backup now
        grp.MapPost("", async (ClaimsPrincipal user, IOptions<LicensingOptions> lic,
                               IOptions<BackupOptions> opt, CancellationToken ct) =>
        {
            if (!lic.Value.IsLocal) return OnlineNotSupported();
            if (!Api.IsAdmin(user)) return Results.Forbid();
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
            if (!Api.IsAdmin(user)) return Results.Forbid();
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
            if (!Api.IsAdmin(user)) return Results.Forbid();
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
            if (!Api.IsAdmin(user)) return Results.Forbid();
            var o = opt.Value;
            var path = SafeBackupPath(o.ResolvedBackupRoot, file);
            if (path is null || !File.Exists(path)) return Results.NotFound();

            // Refuse a backup taken under a DIFFERENT licence (prodkey) — restoring it would
            // overwrite this firm's data with another firm's. backup-local.ps1 stamps the
            // prodkey into the zip's manifest.json. Older backups with no prodkey can't be
            // verified, so they're allowed (don't break existing backups).
            var backupProdKey = TryReadBackupProdKey(path);
            var userProdKey = user.FindFirstValue("prodkey");
            if (!string.IsNullOrEmpty(backupProdKey) && !string.IsNullOrEmpty(userProdKey)
                && !string.Equals(backupProdKey, userProdKey, StringComparison.OrdinalIgnoreCase))
                return Results.Json(new { error = "Restore canceled: product key not same." }, statusCode: 409);

            // write a wrapper .cmd (avoids schtasks nested-quote pain), then run it as a
            // detached one-shot SYSTEM task.
            var script = Path.Combine(o.ResolvedScriptsDir, "restore-local.ps1");
            // Write the launcher to a UNIQUE temp path — NOT the backups folder. That folder
            // is ACL-locked (client PII) and watched by Defender Controlled-Folder-Access, and
            // a FIXED-name wrapper there could be left locked/quarantined by a prior run (AV
            // flags a .cmd that runs PowerShell with a DB password), so every later restore
            // died with UnauthorizedAccessException trying to overwrite it. A fresh GUID name
            // in TEMP can never collide with a locked leftover; the wrapper self-deletes after.
            var wrapper = Path.Combine(Path.GetTempPath(), "SmartTdsRestore_" + Guid.NewGuid().ToString("N") + ".cmd");
            File.WriteAllText(wrapper,
                "@echo off\r\n" +
                $"powershell.exe -ExecutionPolicy Bypass -NoProfile -File \"{script}\" " +
                $"-BackupZip \"{path}\" -PgBin \"{o.ResolvedPgBin}\" -Port {o.Port} " +
                $"-SuperUser {o.SuperUser} -SuperPwd {o.SuperPwd} -Force\r\n" +
                "del \"%~f0\"\r\n");

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
            if (!Api.IsAdmin(user)) return Results.Forbid();
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
        if (!lic.IsLocal) { MigrationsStatus = "skipped"; return; }
        var opt = sp.GetRequiredService<IOptions<BackupOptions>>().Value;
        var log = sp.GetService<ILoggerFactory>()?.CreateLogger("Migrations");
        MigrationsStatus = "pending";
        _ = Task.Run(async () =>
        {
            try
            {
                var (code, so, se) = await RunScript(opt, "migrate-local.ps1", Array.Empty<string>(), CancellationToken.None);
                if (code != 0) { MigrationsStatus = "failed"; log?.LogError("Startup migrations failed: {Err}", Tail(se + so)); }
                else { MigrationsStatus = "ok"; log?.LogInformation("Startup migrations ok: {Out}", Tail(so, 400)); }
            }
            catch (Exception ex) { MigrationsStatus = "failed"; log?.LogError(ex, "Startup migrations threw"); }
        });
    }

    private static IResult OnlineNotSupported() =>
        Results.Problem("Backups are managed server-side in Online mode.", statusCode: 400);

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
                RedirectStandardError = true,
                // pin cwd to the app dir; a Windows service otherwise inherits C:\Windows\System32
                WorkingDirectory = AppContext.BaseDirectory
            };
            using var p = Process.Start(psi);
            p?.WaitForExit(15000);
        }
        catch { /* ignore — restore task creation is best-effort */ }
    }

    // Read the prodkey stamped in the backup zip's manifest.json (by backup-local.ps1).
    // Returns null when the zip has no manifest / no prodkey (older backups) — the caller
    // then can't verify the licence and allows the restore.
    private static string? TryReadBackupProdKey(string zipPath)
    {
        try
        {
            using var zip = System.IO.Compression.ZipFile.OpenRead(zipPath);
            var entry = zip.GetEntry("manifest.json");
            if (entry is null) return null;
            using var s = entry.Open();
            using var doc = System.Text.Json.JsonDocument.Parse(s);
            return doc.RootElement.TryGetProperty("prodkey", out var pk) ? pk.GetString() : null;
        }
        catch { return null; }   // unreadable/old manifest -> can't verify, allow
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
        // -BackupRoot ONLY for the scripts that declare it (backup-local.ps1 / restore-local.ps1).
        // migrate-local.ps1 has no such parameter, so passing it made EVERY startup migration
        // fail ("A parameter cannot be found that matches parameter name 'BackupRoot'") on any
        // install where Backup:BackupRoot is configured — i.e. migrations never applied.
        if (!string.IsNullOrEmpty(o.BackupRoot)
            && (script.Equals("backup-local.ps1", StringComparison.OrdinalIgnoreCase)
             || script.Equals("restore-local.ps1", StringComparison.OrdinalIgnoreCase)))
        { args.Add("-BackupRoot"); args.Add(o.BackupRoot!); }
        args.AddRange(extra);

        var psi = new ProcessStartInfo("powershell.exe")
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            // pin cwd to the app dir; a Windows service otherwise inherits C:\Windows\System32,
            // so any relative path inside the .ps1 (or its pg_dump/psql children) would resolve
            // against system32 instead of the install.
            WorkingDirectory = AppContext.BaseDirectory
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
