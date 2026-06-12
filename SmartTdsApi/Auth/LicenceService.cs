using System.Collections.Concurrent;
using System.Globalization;
using System.Net.NetworkInformation;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Xml.Linq;
using Dapper;
using Microsoft.Extensions.Options;
using SmartTdsApi.Data;

namespace SmartTdsApi.Auth;

/// <summary>
/// Licence authority = the legacy smartbizin <c>ServiceUL.svc</c> SOAP service
/// (replaces the old desktop Pump.cs flow, now server-side). Validates a licence
/// key (prodkey) bound to this server's machine-id, returns expiry + registered-to,
/// and caches a successful result for <see cref="LicensingOptions.RecheckHours"/>.
/// Machine binding is STRICT in BOTH modes — one key, one server (the VPS for cloud
/// keys, the LAN server for local keys). A firm with both deployments gets one key
/// per deployment (the PRODKEY_&lt;n&gt; convention). Modes still differ on seats:
/// Online enforces max_seats, Local is unlimited.
/// </summary>
public sealed class LicenceService
{
    private const string Soap11 = "http://schemas.xmlsoap.org/soap/envelope/";
    private const string Tempuri = "http://tempuri.org/";
    private const string SoapAction = "http://tempuri.org/IServiceUL/CheckOnlineNoIP";

    private readonly LicensingOptions _opt;
    private readonly IHttpClientFactory _http;
    private readonly IDbConnectionFactory _db;
    private readonly ILogger<LicenceService> _log;
    private readonly ConcurrentDictionary<string, LicenceResult> _cache = new();

    public string MachineId { get; }

    public LicenceService(IOptions<LicensingOptions> opt, IHttpClientFactory http,
        IDbConnectionFactory db, ILogger<LicenceService> log)
    {
        _opt = opt.Value; _http = http; _db = db; _log = log;
        MachineId = GetOrCreateMachineId();
        _log.LogInformation("Licensing mode={Mode} machineId={Mid}", _opt.Mode, MachineId);
    }

    /// <summary>
    /// Validate a licence key. Three layers, mirroring the legacy desktop Pump.cs flow:
    ///  1. in-memory cache (RecheckHours) — skips everything;
    ///  2. the encrypted blob persisted in applicationparams.auth (Pump's EncryptToDb) —
    ///     survives API restarts, machine-bound, trusted within RecheckHours;
    ///  3. live ServiceUL call. Success refreshes the blob; an UNREACHABLE service falls
    ///     back to the blob for up to GraceDays (Pump's offline window); a hard rejection
    ///     (invalid / expired / bound elsewhere) WIPES the blob (Pump's WriteToDb("")).
    /// </summary>
    public async Task<LicenceResult> ValidateAsync(string prodKey, CancellationToken ct)
    {
        var key = (prodKey ?? "").Trim().ToUpperInvariant();
        if (key.Length == 0) return LicenceResult.Fail("Licence key is required.");

        // All licence maths uses the TRUSTED date (port of legacy ImpData.GetDtOnline) —
        // never the box's own clock, which a LAN customer could roll back to stretch
        // grace / expiry.
        var nowUtc = await TrustedUtcNowAsync(ct);

        if (_cache.TryGetValue(key, out var cached)
            && cached.Allowed
            && cached.CheckedUtc.AddHours(Math.Max(1, _opt.RecheckHours)) > nowUtc)
            return cached;

        // Layer 2: the persisted blob (validates key + machine-id + expiry on load).
        var stored = await LoadStoredAsync(key, nowUtc, ct);
        if (stored is not null
            && stored.CheckedUtc.AddHours(Math.Max(1, _opt.RecheckHours)) > nowUtc)
        {
            var fromDb = new LicenceResult(true, stored.Status, stored.Expiry, stored.RegisteredTo, "OK", stored.CheckedUtc);
            _cache[key] = fromDb;
            return fromDb;
        }

        // Layer 3: live check.
        var result = await CallServiceAsync(key, nowUtc, ct);
        if (result.Allowed)
        {
            _cache[key] = result;
            // Persist PAID results only — Pump always re-validated Demo against the service,
            // so a demo licence gets no offline grace.
            if (!IsDemo(result.Status)) await PersistAsync(key, result, ct);
            return result;
        }

        // Unreachable (network/DNS/down — NOT a rejection): Pump's offline grace.
        if (result.Status == "Error" && stored is not null
            && stored.CheckedUtc.AddDays(Math.Max(1, _opt.GraceDays)) > nowUtc)
        {
            var grace = new LicenceResult(true, stored.Status, stored.Expiry, stored.RegisteredTo,
                "Licence server unreachable — allowed from the last successful validation (offline grace).",
                stored.CheckedUtc);
            _cache[key] = grace;
            _log.LogWarning("Licence {Key}: ServiceUL unreachable; allowed via offline grace (last check {When:u})",
                key, stored.CheckedUtc);
            return grace;
        }

        // Hard rejection: wipe the blob so the grace window can't resurrect a dead licence.
        if (result.Status != "Error") await WipeAsync(key, ct);
        return result;
    }

    private static bool IsDemo(string status)
        => (status ?? "").IndexOf("Demo", StringComparison.OrdinalIgnoreCase) >= 0;

    // ---- trusted date (port of legacy ImpData.GetDtOnline) ----
    // The legacy desktop never trusted the PC clock for licence maths — it fetched the
    // date from smartbizin's DateService, then NIST, then (only as a last resort) the
    // local clock. Same chain here: the smartbizin hosts' HTTP Date response header
    // (same servers, no SOAP contract needed) -> NIST daytime -> local UTC. The offset
    // is cached for an hour keyed on Environment.TickCount64, which keeps counting
    // monotonically even if someone changes the system clock mid-run.
    private readonly object _timeLock = new();
    private long _trustedAtTicks = -1;
    private TimeSpan _trustedOffset = TimeSpan.Zero;

    private async Task<DateTime> TrustedUtcNowAsync(CancellationToken ct)
    {
        lock (_timeLock)
        {
            if (_trustedAtTicks >= 0 && Environment.TickCount64 - _trustedAtTicks < 3_600_000)
                return DateTime.UtcNow + _trustedOffset;
        }

        var fetched = await FetchNetworkUtcAsync(ct);
        lock (_timeLock)
        {
            _trustedOffset = fetched.HasValue ? fetched.Value - DateTime.UtcNow : TimeSpan.Zero;
            _trustedAtTicks = Environment.TickCount64;
            return DateTime.UtcNow + _trustedOffset;
        }
    }

    private async Task<DateTime?> FetchNetworkUtcAsync(CancellationToken ct)
    {
        // 1) HTTP Date header from the smartbizin hosts (the legacy DateService servers).
        foreach (var url in _opt.ServiceUrls)
        {
            try
            {
                var client = _http.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(5);
                using var req = new HttpRequestMessage(HttpMethod.Head, new Uri(new Uri(url), "/"));
                using var resp = await client.SendAsync(req, ct);
                if (resp.Headers.Date.HasValue) return resp.Headers.Date.Value.UtcDateTime;
            }
            catch { /* try next source */ }
        }
        // 2) NIST daytime protocol — the exact legacy fallback (time.nist.gov:13).
        try
        {
            using var tcp = new System.Net.Sockets.TcpClient();
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
            cts.CancelAfter(TimeSpan.FromSeconds(5));
            await tcp.ConnectAsync("time.nist.gov", 13, cts.Token);
            using var sr = new StreamReader(tcp.GetStream());
            var response = await sr.ReadToEndAsync(cts.Token);
            // "JJJJJ YY-MM-DD HH:MM:SS TT L H msADV UTC(NIST) *"
            var utcText = response.Substring(7, 17);
            return DateTime.ParseExact(utcText, "yy-MM-dd HH:mm:ss",
                CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal);
        }
        catch { /* fall through */ }
        // 3) last resort: the box clock (legacy did the same).
        _log.LogDebug("No network time source reachable; falling back to the local clock");
        return null;
    }

    // ---- ServiceUL SOAP call (primary then fallback) ----
    private async Task<LicenceResult> CallServiceAsync(string prodKey, DateTime nowUtc, CancellationToken ct)
    {
        var body =
            $"<s:Envelope xmlns:s=\"{Soap11}\" xmlns:t=\"{Tempuri}\"><s:Body>" +
            "<t:CheckOnlineNoIP>" +
            $"<t:auth>{X(_opt.Auth)}</t:auth>" +
            $"<t:pname>{X(_opt.ProductName)}</t:pname>" +
            $"<t:regkey>{X(prodKey)}</t:regkey>" +
            $"<t:HDid>{X(MachineId)}</t:HDid>" +
            $"<t:licencetype>{X(_opt.LicenceType)}</t:licencetype>" +
            "</t:CheckOnlineNoIP></s:Body></s:Envelope>";

        foreach (var url in _opt.ServiceUrls)
        {
            try
            {
                var client = _http.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(15);
                using var msg = new HttpRequestMessage(HttpMethod.Post, url)
                {
                    Content = new StringContent(body, Encoding.UTF8, "text/xml")
                };
                msg.Headers.TryAddWithoutValidation("SOAPAction", $"\"{SoapAction}\"");
                msg.Headers.TryAddWithoutValidation("User-Agent", "Chrome");

                using var resp = await client.SendAsync(msg, ct);
                var xml = await resp.Content.ReadAsStringAsync(ct);
                if (!resp.IsSuccessStatusCode)
                {
                    _log.LogWarning("ServiceUL {Url} -> HTTP {Code}", url, (int)resp.StatusCode);
                    continue;
                }
                var arr = ParseResult(xml);
                if (arr.Count == 0) { _log.LogWarning("ServiceUL {Url} -> empty result", url); continue; }
                return Interpret(arr, nowUtc);
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "ServiceUL {Url} call failed", url);
            }
        }
        return LicenceResult.Fail("Could not reach the licence server. Check the internet connection and try again.");
    }

    // ---- map the ServiceUL string[] to a verdict (mirrors legacy Pump.CallValidationService) ----
    private LicenceResult Interpret(IReadOnlyList<string> res, DateTime nowUtc)
    {
        string status = res[0] ?? "";
        var expiry = res.Count > 5 ? ParseDate(res[5]) : null;
        var registeredTo = res.Count > 8 ? (res[8] ?? "") : "";
        var today = nowUtc.Date;   // trusted date, not the box clock

        // STRICT machine binding in BOTH modes (user decision 2026-06-12): a key bound to
        // another machine is rejected on the cloud too — otherwise a local-server licence
        // would double as a cloud licence. Deployments get their own key (PRODKEY_<n>);
        // each key binds to ITS server's machine-id at first login (the VPS for cloud).
        // ServiceUL's "Product Key Already in use" message (with both machine-ids and the
        // release instruction) is relayed to the user as-is by the fall-through below.

        if (status == "ComeIn")
        {
            if (expiry.HasValue && expiry.Value.Date < today)
                return new LicenceResult(false, status, expiry, registeredTo,
                    $"Licence expired on {expiry:dd MMM yyyy}. Kindly contact your dealer to renew.", nowUtc);
            return new LicenceResult(true, status, expiry, registeredTo, "OK", nowUtc);
        }
        if (status.Contains("Your Demo will expire in", StringComparison.OrdinalIgnoreCase))
            return new LicenceResult(true, status, expiry, registeredTo, "Demo version.", nowUtc);
        if (status == "GetLost")
            return new LicenceResult(false, status, expiry, registeredTo, "Product key is either invalid or expired.", nowUtc);
        if (status.StartsWith("Licence Expired", StringComparison.OrdinalIgnoreCase))
            return new LicenceResult(false, status, expiry, registeredTo, "Licence expired. Kindly renew.", nowUtc);

        // anything else: deny, surface the server's message
        return new LicenceResult(false, status, expiry, registeredTo,
            string.IsNullOrWhiteSpace(status) ? "Licence validation failed." : status, nowUtc);
    }

    private static List<string> ParseResult(string xml)
    {
        var list = new List<string>();
        try
        {
            var doc = XDocument.Parse(xml);
            // the result is <CheckOnlineNoIPResult><a:string>..</a:string>..; grab all "string" elements in order
            foreach (var e in doc.Descendants().Where(e => e.Name.LocalName == "string"))
                list.Add(e.Value);
        }
        catch { /* malformed -> empty */ }
        return list;
    }

    private static DateTime? ParseDate(string? s)
    {
        if (string.IsNullOrWhiteSpace(s)) return null;
        string[] fmts = { "M/d/yyyy", "d/M/yyyy", "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "d-M-yyyy" };
        if (DateTime.TryParseExact(s.Trim(), fmts, CultureInfo.InvariantCulture, DateTimeStyles.None, out var d)) return d;
        if (DateTime.TryParse(s.Trim(), CultureInfo.InvariantCulture, DateTimeStyles.None, out d)) return d;
        return null;
    }

    private static string X(string? s) => System.Security.SecurityElement.Escape(s ?? "") ?? "";

    // ---- machine id (binds the licence to this server) ----
    // HARDWARE-FIRST, recomputed on EVERY start — the legacy Pump.cs model (it hashed
    // the BIOS serial each run). A previous version trusted a persisted machineid.dat,
    // which is just a file: copying ProgramData\SmartTds to a second server cloned the
    // licence identity. Now the id derives from the machine itself:
    //   Windows: HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid (unique per Windows
    //            install — survives NIC swaps; changes only on an OS reinstall)
    //   Linux:   /etc/machine-id (the standard stable per-install identity; VPS)
    // machineid.dat is kept ONLY as (a) a diagnostics copy of the current id and
    // (b) the fallback when no hardware identity is readable. On a cloned box the
    // copied file is ignored and overwritten with that box's own hardware id.
    private string GetOrCreateMachineId()
    {
        var path = _opt.MachineIdFile;
        if (string.IsNullOrWhiteSpace(path))
        {
            var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "SmartTds");
            path = Path.Combine(dir, "machineid.dat");
        }

        var hw = TryHardwareIdentity();
        if (hw is not null)
        {
            var hwId = Hash16("SmartTds.MachineId.v2|" + hw);
            TryPersistId(path, hwId);   // best-effort cache for support + the fallback below
            return hwId;
        }

        // No hardware identity readable (rare) — fall back to the persisted id so the
        // licence keeps working, creating it once if missing.
        _log.LogWarning("No hardware machine identity readable; falling back to {Path}", path);
        try
        {
            if (File.Exists(path))
            {
                var existing = File.ReadAllText(path).Trim();
                if (existing.Length > 0) return existing;
            }
        }
        catch { /* fall through to (re)create */ }

        var seed = TryHardwareSeed() ?? Guid.NewGuid().ToString("N");
        var id = Hash16(seed);
        TryPersistId(path, id);
        return id;
    }

    /// <summary>
    /// OS-install-bound identity with a Pump.cs-style fallback ladder (the legacy
    /// desktop fell back BIOS serial -> drive id -> registry). Each rung is tried
    /// independently; only when ALL fail does the caller use the persisted file.
    ///   Windows: MachineGuid -> ComputerHardwareId -> ProductId+InstallDate
    ///            -> system-volume serial ("drive id")
    ///   Linux:   /etc/machine-id -> /var/lib/dbus/machine-id
    /// Sources are prefix-tagged so two different sources can never hash alike.
    /// </summary>
    private static string? TryHardwareIdentity()
    {
        if (OperatingSystem.IsWindows())
        {
            try
            {
                var guid = Microsoft.Win32.Registry.GetValue(
                    @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography", "MachineGuid", null) as string;
                if (!string.IsNullOrWhiteSpace(guid)) return "winguid:" + guid.Trim();
            }
            catch { }
            try
            {
                // Hardware-derived GUID Windows computes from SMBIOS (BIOS/board) data.
                var hw = Microsoft.Win32.Registry.GetValue(
                    @"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SystemInformation",
                    "ComputerHardwareId", null) as string;
                if (!string.IsNullOrWhiteSpace(hw)) return "winhw:" + hw.Trim();
            }
            catch { }
            try
            {
                // Windows licence identity + install timestamp — stable per OS install.
                const string cv = @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion";
                var pid = Microsoft.Win32.Registry.GetValue(cv, "ProductId", null) as string;
                var inst = Microsoft.Win32.Registry.GetValue(cv, "InstallDate", null);
                if (!string.IsNullOrWhiteSpace(pid)) return "winpid:" + pid.Trim() + "|" + inst;
            }
            catch { }
            try
            {
                // The legacy Pump "drive id": serial of the system volume. Last hardware
                // rung — it changes on a format, but a format means OS reinstall anyway.
                var root = Path.GetPathRoot(Environment.SystemDirectory);
                if (root is not null
                    && GetVolumeInformationW(root, null, 0, out var serial, out _, out _, null, 0)
                    && serial != 0)
                    return "windrive:" + serial.ToString("X8");
            }
            catch { }
        }
        else
        {
            foreach (var p in new[] { "/etc/machine-id", "/var/lib/dbus/machine-id" })
            {
                try
                {
                    if (File.Exists(p))
                    {
                        var mid = File.ReadAllText(p).Trim();
                        if (mid.Length > 0) return "linuxid:" + mid;
                    }
                }
                catch { }
            }
        }
        return null;
    }

    [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = false)]
    private static extern bool GetVolumeInformationW(
        string lpRootPathName, StringBuilder? lpVolumeNameBuffer, int nVolumeNameSize,
        out uint lpVolumeSerialNumber, out uint lpMaximumComponentLength, out uint lpFileSystemFlags,
        StringBuilder? lpFileSystemNameBuffer, int nFileSystemNameSize);

    private static string Hash16(string seed)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(seed))).Substring(0, 16);

    private void TryPersistId(string path, string id)
    {
        try
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            // Only rewrite when changed, so the file's timestamp stays meaningful.
            if (!File.Exists(path) || File.ReadAllText(path).Trim() != id)
                File.WriteAllText(path, id);
        }
        catch (Exception ex) { _log.LogWarning(ex, "Could not persist machineId to {Path}", path); }
    }

    private static string? TryHardwareSeed()
    {
        try
        {
            var nic = NetworkInterface.GetAllNetworkInterfaces()
                .Where(n => n.OperationalStatus == OperationalStatus.Up
                            && n.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                .OrderBy(n => n.Id)
                .FirstOrDefault();
            var mac = nic?.GetPhysicalAddress().ToString();
            return string.IsNullOrWhiteSpace(mac) ? null : mac;
        }
        catch { return null; }
    }

    // ---- persisted licence blob in applicationparams (port of Pump.cs EncryptToDb /
    // DecryptFromDb / WriteToDb("")). AES key is derived from THIS machine's id, so a
    // DB copied to another machine can't reuse the blob — same effect as Pump's
    // stored-_pcId-vs-regenerated check, enforced by the crypto itself. ----

    private sealed record StoredLicence(
        string Key, string MachineId, string Status, string RegisteredTo, DateTime? Expiry, DateTime CheckedUtc);

    // Local = one firm per server -> the legacy 'auth' row. Online = shared masterdbtds,
    // many firms -> one row per licence key ('auth:<KEY>').
    private string AuthRowName(string key) => _opt.IsLocal ? "auth" : "auth:" + key;

    private async Task<StoredLicence?> LoadStoredAsync(string key, DateTime nowUtc, CancellationToken ct)
    {
        try
        {
            using var conn = await _db.OpenMasterAsync(ct);
            var blob = await conn.QueryFirstOrDefaultAsync<string>(new CommandDefinition(
                "select value from applicationparams where name=@n limit 1",
                new { n = AuthRowName(key) }, cancellationToken: ct));
            if (string.IsNullOrWhiteSpace(blob)) return null;

            var s = JsonSerializer.Deserialize<StoredLicence>(DecryptBlob(blob));
            if (s is null) return null;
            if (!string.Equals(s.Key, key, StringComparison.OrdinalIgnoreCase)) return null;        // key changed -> revalidate
            if (!string.Equals(s.MachineId, MachineId, StringComparison.OrdinalIgnoreCase)) return null; // machine changed -> revalidate
            if (s.Expiry.HasValue && s.Expiry.Value.Date < nowUtc.Date) return null;                // expired -> no grace
            if (s.CheckedUtc > nowUtc.AddHours(2)) return null;   // blob from "the future" = clock rolled back -> revalidate
            return s;
        }
        catch (Exception ex)
        {
            // Unreadable blob (legacy Pump format, different machine, manual edit) — not an
            // error: just fall through to a live ServiceUL validation, which rewrites it.
            _log.LogDebug(ex, "Stored licence blob for {Key} unreadable; will revalidate", key);
            return null;
        }
    }

    private async Task PersistAsync(string key, LicenceResult res, CancellationToken ct)
    {
        try
        {
            var payload = JsonSerializer.Serialize(
                new StoredLicence(key, MachineId, res.Status, res.RegisteredTo, res.Expiry, res.CheckedUtc));
            await UpsertParamAsync(AuthRowName(key), EncryptBlob(payload), ct);
        }
        catch (Exception ex)
        {
            // Persistence is belt-and-braces; never let it block a successful login.
            _log.LogWarning(ex, "Could not persist licence blob for {Key}", key);
        }
    }

    private async Task WipeAsync(string key, CancellationToken ct)
    {
        try { await UpsertParamAsync(AuthRowName(key), "", ct); }
        catch (Exception ex) { _log.LogWarning(ex, "Could not wipe licence blob for {Key}", key); }
    }

    private async Task UpsertParamAsync(string name, string value, CancellationToken ct)
    {
        using var conn = await _db.OpenMasterAsync(ct);
        var n = await conn.ExecuteAsync(new CommandDefinition(
            "update applicationparams set value=@v where name=@n",
            new { v = value, n = name }, cancellationToken: ct));
        if (n == 0)
            await conn.ExecuteAsync(new CommandDefinition(
                "insert into applicationparams (name, value) values (@n, @v)",
                new { v = value, n = name }, cancellationToken: ct));
    }

    private byte[] BlobKey()
        => SHA256.HashData(Encoding.UTF8.GetBytes("SmartTds.LicenceBlob.v1|" + MachineId));

    private string EncryptBlob(string plaintext)
    {
        using var aes = Aes.Create();
        aes.Key = BlobKey();
        aes.GenerateIV();
        using var enc = aes.CreateEncryptor();
        var data = Encoding.UTF8.GetBytes(plaintext);
        var cipher = enc.TransformFinalBlock(data, 0, data.Length);
        var raw = new byte[aes.IV.Length + cipher.Length];
        Buffer.BlockCopy(aes.IV, 0, raw, 0, aes.IV.Length);
        Buffer.BlockCopy(cipher, 0, raw, aes.IV.Length, cipher.Length);
        return Convert.ToBase64String(raw);
    }

    private string DecryptBlob(string blob)
    {
        var raw = Convert.FromBase64String(blob);
        using var aes = Aes.Create();
        aes.Key = BlobKey();
        aes.IV = raw.AsSpan(0, 16).ToArray();
        using var dec = aes.CreateDecryptor();
        var plain = dec.TransformFinalBlock(raw, 16, raw.Length - 16);
        return Encoding.UTF8.GetString(plain);
    }
}
