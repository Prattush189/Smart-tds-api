using System.Collections.Concurrent;
using System.Globalization;
using System.Net.NetworkInformation;
using System.Security.Cryptography;
using System.Text;
using System.Xml.Linq;
using Microsoft.Extensions.Options;

namespace SmartTdsApi.Auth;

/// <summary>
/// Licence authority = the legacy smartbizin <c>ServiceUL.svc</c> SOAP service
/// (replaces the old desktop Pump.cs flow, now server-side). Validates a licence
/// key (prodkey) bound to this server's machine-id, returns expiry + registered-to,
/// and caches a successful result for <see cref="LicensingOptions.RecheckHours"/>.
/// Online mode tolerates a key already bound to another machine (shared cloud);
/// Local mode is strict (one key = one LAN server).
/// </summary>
public sealed class LicenceService
{
    private const string Soap11 = "http://schemas.xmlsoap.org/soap/envelope/";
    private const string Tempuri = "http://tempuri.org/";
    private const string SoapAction = "http://tempuri.org/IServiceUL/CheckOnlineNoIP";

    private readonly LicensingOptions _opt;
    private readonly IHttpClientFactory _http;
    private readonly ILogger<LicenceService> _log;
    private readonly ConcurrentDictionary<string, LicenceResult> _cache = new();

    public string MachineId { get; }

    public LicenceService(IOptions<LicensingOptions> opt, IHttpClientFactory http, ILogger<LicenceService> log)
    {
        _opt = opt.Value; _http = http; _log = log;
        MachineId = GetOrCreateMachineId();
        _log.LogInformation("Licensing mode={Mode} machineId={Mid}", _opt.Mode, MachineId);
    }

    /// <summary>Validate a licence key. Cached successes skip the network call within RecheckHours.</summary>
    public async Task<LicenceResult> ValidateAsync(string prodKey, CancellationToken ct)
    {
        var key = (prodKey ?? "").Trim().ToUpperInvariant();
        if (key.Length == 0) return LicenceResult.Fail("Licence key is required.");

        if (_cache.TryGetValue(key, out var cached)
            && cached.Allowed
            && cached.CheckedUtc.AddHours(Math.Max(1, _opt.RecheckHours)) > DateTime.UtcNow)
            return cached;

        var result = await CallServiceAsync(key, ct);
        if (result.Allowed) _cache[key] = result;   // only cache good results
        return result;
    }

    // ---- ServiceUL SOAP call (primary then fallback) ----
    private async Task<LicenceResult> CallServiceAsync(string prodKey, CancellationToken ct)
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
                return Interpret(arr);
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "ServiceUL {Url} call failed", url);
            }
        }
        return LicenceResult.Fail("Could not reach the licence server. Check the internet connection and try again.");
    }

    // ---- map the ServiceUL string[] to a verdict (mirrors legacy Pump.CallValidationService) ----
    private LicenceResult Interpret(IReadOnlyList<string> res)
    {
        string status = res[0] ?? "";
        var expiry = res.Count > 5 ? ParseDate(res[5]) : null;
        var registeredTo = res.Count > 8 ? (res[8] ?? "") : "";
        var today = DateTime.UtcNow.Date;

        // Online (shared cloud): a key already bound to another machine is OK if not expired.
        if (_opt.IsOnline && status.Contains("Product Key Already in use", StringComparison.OrdinalIgnoreCase)
            && expiry.HasValue && expiry.Value.Date >= today)
            status = "ComeIn";

        if (status == "ComeIn")
        {
            if (expiry.HasValue && expiry.Value.Date < today)
                return new LicenceResult(false, status, expiry, registeredTo,
                    $"Licence expired on {expiry:dd MMM yyyy}. Kindly contact your dealer to renew.", DateTime.UtcNow);
            return new LicenceResult(true, status, expiry, registeredTo, "OK", DateTime.UtcNow);
        }
        if (status.Contains("Your Demo will expire in", StringComparison.OrdinalIgnoreCase))
            return new LicenceResult(true, status, expiry, registeredTo, "Demo version.", DateTime.UtcNow);
        if (status == "GetLost")
            return new LicenceResult(false, status, expiry, registeredTo, "Product key is either invalid or expired.", DateTime.UtcNow);
        if (status.StartsWith("Licence Expired", StringComparison.OrdinalIgnoreCase))
            return new LicenceResult(false, status, expiry, registeredTo, "Licence expired. Kindly renew.", DateTime.UtcNow);

        // anything else: deny, surface the server's message
        return new LicenceResult(false, status, expiry, registeredTo,
            string.IsNullOrWhiteSpace(status) ? "Licence validation failed." : status, DateTime.UtcNow);
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

    // ---- stable, persisted machine id (binds the licence to this server) ----
    private string GetOrCreateMachineId()
    {
        var path = _opt.MachineIdFile;
        if (string.IsNullOrWhiteSpace(path))
        {
            var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "SmartTds");
            path = Path.Combine(dir, "machineid.dat");
        }
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
        var id = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(seed))).Substring(0, 16);
        try
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            File.WriteAllText(path, id);
        }
        catch (Exception ex) { _log.LogWarning(ex, "Could not persist machineId to {Path}; using in-memory id", path); }
        return id;
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
}
