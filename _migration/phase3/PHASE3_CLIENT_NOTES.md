# Phase 3 — Client Refactor (desktop → API)  ✅ foundation built & validated

The desktop now has a single, tested doorway to the server. The full screen-by-screen port is mechanical repetition of the pattern below; the **infrastructure and the proven slice are done**.

## CURRENT STATUS (deployment in progress)
- **Backend LIVE** at `https://api.smartbizin.com` (VPS 66.116.224.29): PostgreSQL 14 + API (systemd) + HTTPS + licensing. Login validated from the desktop client lib against prod.
- **Login WIRED into the desktop**: `app.config` (`UseApi=true`, `ApiBaseUrl=https://api.smartbizin.com`), `Common/AppApi.cs` (accessor + UserInfo→User map), `Masters/Users/FrmLogin.cs` (API branch + skips SQL-only FrmUpdateDb/FrmBackup). API login now returns the full user (id+permission flags).
- **csproj fixed so it BUILDS**: added `<Reference Include="SmartTds.ApiClient">` (HintPath `Lib\Dlls\SmartTds.ApiClient.dll`, copied there) + `<Reference Include="System.Net.Http" />`. `Common\AppApi.cs` is registered as `<Compile Include>`.

## ⚠️ RULE for this old-style .csproj (every new file must be registered)
SmartTdsWinUI uses the classic project format — files are NOT auto-included. When adding to the WinForms project:
- New `.cs` → add `<Compile Include="Path\File.cs" />` to a `<ItemGroup>` in `SmartTdsWinUI.csproj`.
- New referenced DLL → drop it in `Lib\Dlls\` and add `<Reference Include="Name"><HintPath>Lib\Dlls\Name.dll</HintPath></Reference>`.
- New form → add the `.cs`, `.Designer.cs` (with `<DependentUpon>`), and `.resx` (`<EmbeddedResource>` + `<DependentUpon>`).
Otherwise the build throws "type or namespace not found".

## What is NOT done (the remaining bulk — do incrementally, compiling each)
The data screens still call BAL → SQL Server. They CANNOT be blind-ported because each needs (a) an API endpoint built first and (b) a compile in VS2022 (DevExpress). Order: build each endpoint API-side → wire the screen behind `UseApi` → test. See the port checklist near the end.

### DataSet conversion (the user's question)
`SmartTdsWinUI/MasterDbTdsDataSet.xsd` is a typed DataSet whose TableAdapters do billing CRUD with `SCOPE_IDENTITY()` (SQL-Server-only). "Converting" it = **porting the billing screens** to the API (new billing endpoints + replace the TableAdapter calls). It is NOT a mechanical find/replace and is part of the per-screen port (billing), not a standalone step.

## What's built (and validated against the live, hardened API)
- **`SmartTds.ApiClient`** — class library, multi-targeted **`net452;net8.0`** (net452 = the WinForms app's framework, so it drops straight in). Newtonsoft.Json (already in the app), `HttpClient`, **TLS 1.2 enabled for .NET 4.5.2** (`ServicePointManager.SecurityProtocol |= Tls12`), JWT bearer token handling, typed DTOs, `ApiException` with server message + status.
  - `IApiClient`: `LoginAsync`, `GetAssesseesAsync`, `GetAssesseeAsync`, `GetChallansAsync(year, subCode)`.
- **`SmartTds.ApiClient.SmokeTest`** — console that exercises the SAME library end-to-end. **All checks pass**: login, assessees (master DB), challans (year-routed DB), firm filter, 401 when unauthenticated, clean 404 for unknown year.

## The strangler pattern (how to port the rest safely)
Old and new coexist behind a config flag, so you migrate one screen at a time and can roll back instantly.

**1. Add a flag + a single accessor** (drop this into `SmartTdsWinUI`, e.g. `Common/AppApi.cs`):
```csharp
public static class AppApi
{
    // app.config: <add key="UseApi" value="true"/>  and  <add key="ApiBaseUrl" value="https://api.smarttds..."/>
    public static bool UseApi =>
        string.Equals(ConfigurationManager.AppSettings["UseApi"], "true", StringComparison.OrdinalIgnoreCase);

    private static IApiClient _client;
    public static IApiClient Client => _client ??= new ApiClient(new ApiClientOptions
        { BaseUrl = ConfigurationManager.AppSettings["ApiBaseUrl"] });
}
```

**2. Branch at each call site.** Example — the assessee list (today it calls `AssesseeBal`):
```csharp
// BEFORE (direct DB):
var list = new AssesseeBal().GetAll();          // hits SQL Server via the BAL

// AFTER (strangler):
if (AppApi.UseApi)
{
    var dtos = AppApi.Client.GetAssesseesAsync().GetAwaiter().GetResult();  // sync-over-async for WinForms handlers
    // map dtos -> the grid's binding type (or bind dtos directly)
}
else
{
    var list = new AssesseeBal().GetAll();       // legacy path, unchanged
}
```
> For responsiveness, prefer `async`/`await` in event handlers (`private async void btn_Click`). The sync `.GetAwaiter().GetResult()` form is the quickest drop-in where you can't go async yet.

**3. Login** flows through `AppApi.Client.LoginAsync(...)` once; the token is held by the client and auto-attached to every later call.

## ⚠️ The #1 rule while porting: COARSEN endpoints
This is Phase 0 risk #6 and the single biggest perf trap. A screen that made 30 in-process BAL calls must **not** become 30 WAN round-trips. For each screen, add **one** API endpoint that returns everything the screen needs in a single response (e.g. `GET /api/assessees/{id}/dashboard` returning assessee + challans + payees together), then bind the screen to that one call. Build the endpoint API-side first, then wire the screen.

## Port checklist (drives the remaining work)
Use the Phase 0 inventory ([PHASE0_INVENTORY.md](../phase0/PHASE0_INVENTORY.md)) as the worklist — 190 BAL methods across ~47 classes. Recommended order (low-risk → high):
1. ✅ Auth / login (done)
2. ✅ Assessee list/detail (done)  ·  ✅ Challan list (done)
3. Masters/reference reads (states, pincodes, tax rates) — pure reads, easy
4. Payee, TdsEntry, Salary CRUD — coarse per-screen endpoints
5. Billing (BillHead/BillReceipts) — **also fix `MAX+1` → sequences here** (deadline-concurrency hazard)
6. Cross-DB lookups (`TdsPayeeBal` 3-part name) — API reads master + year separately
7. Remove the hardcoded connection string from the client (the big security win)

## Build/verify locally
```powershell
dotnet build "SmartTds.ApiClient\SmartTds.ApiClient.csproj"      # net452 + net8.0
# with API running (see Phase 2 notes):
dotnet run --project "SmartTds.ApiClient.SmokeTest"               # all client tests pass
```

## Status
Foundation + slice **complete and validated**. Remaining = apply the pattern to each screen (mechanical, behind the flag). Full app compile requires the DevExpress 22.2 toolchain on the build machine; the client library itself compiles standalone for net452.
