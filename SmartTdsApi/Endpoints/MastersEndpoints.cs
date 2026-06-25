using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ── DTOs ──────────────────────────────────────────────────────────────────────

public sealed record StateDto
{
    public int Id { get; init; }
    public int Code { get; init; }
    public string Name { get; init; } = string.Empty;
}

public sealed record CountryDto
{
    public int Id { get; init; }
    public int Code { get; init; }
    public string Name { get; init; } = string.Empty;
}

public sealed record DistrictDto
{
    public int Id { get; init; }
    public int Code { get; init; }
    public int StateCode { get; init; }
    public string Name { get; init; } = string.Empty;
}

public sealed record PostOfficeDto
{
    public int Id { get; init; }
    public int Code { get; init; }
    public string Name { get; init; } = string.Empty;
}

public sealed record SubDistrictDto
{
    public int Id { get; init; }
    public int Code { get; init; }
    public string Name { get; init; } = string.Empty;
}

public sealed record PincodeDto
{
    public int Id { get; init; }
    public double Pincode { get; init; }
    public double DistrictCode { get; init; }
    public double StateCode { get; init; }
    public double SubDistrictCode { get; init; }
    public double LocalityCode { get; init; }
    public double PostOfficeCode { get; init; }
}

public sealed record AyMasterDto
{
    public int Id { get; init; }
    public int AyId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string StartDt { get; init; } = string.Empty;
    public string EndDt { get; init; } = string.Empty;
    public string? NonBusInc { get; init; }
    public string? BusInc { get; init; }
    public string? AuditCase { get; init; }
    public string? CompCase { get; init; }
    public string? Case94E { get; init; }
    public string? AdvInst1 { get; init; }
    public string? AdvInst2 { get; init; }
    public string? AdvInst3 { get; init; }
    public string? AdvInst4 { get; init; }
    public string? UpdNonBusInc { get; init; }
    public string? UpdBusInc { get; init; }
    public string? UpdAuditCase { get; init; }
    public string? UpdCompCase { get; init; }
    public string? UpdCase94E { get; init; }
}

// Output shape with DateTime fields (parsed from the dd/MM/yyyy varchars) so the desktop's
// MasterEntities.AyMaster (DateTime properties) deserializes correctly. Concrete type =
// System.Text.Json serializes all properties (a List<object> of anonymous types would not).
public sealed record AyMasterOut(
    int Id, int AyId, string Name, DateTime StartDt, DateTime EndDt,
    DateTime NonBusInc, DateTime BusInc, DateTime AuditCase, DateTime CompCase, DateTime Case94E,
    DateTime AdvInst1, DateTime AdvInst2, DateTime AdvInst3, DateTime AdvInst4,
    DateTime UpdNonBusInc, DateTime UpdBusInc, DateTime UpdAuditCase, DateTime UpdCompCase, DateTime UpdCase94E);

public sealed record TdsNatureDto
{
    public int Code { get; init; }
    public string Particular { get; init; } = string.Empty;
}

public sealed record TdsRateDto
{
    public int AyId { get; init; }
    public int TsId { get; init; }
    public int PayCode { get; init; }
    public decimal Rate { get; init; }
    public decimal Surch { get; init; }
    public int Limit { get; init; }
}

public sealed record Tdsded80Dto
{
    public int Ded80Id { get; init; }
    public string? DedSec { get; init; }
    public string? Ded80Name { get; init; }
    public string? Ded80Table { get; init; }
    public string? Label1 { get; init; }
    public string? Label2 { get; init; }
    public string? Label3 { get; init; }
    public string? Label4 { get; init; }
    public string? Label5 { get; init; }
    public string? Label6 { get; init; }
    public string? Label7 { get; init; }
    public string? Label8 { get; init; }
    public string? Label9 { get; init; }
    public string? Label10 { get; init; }
    public string? DedType { get; init; }
    public int PdedId { get; init; }
    public string? Section { get; init; }
    public string? Short { get; init; }
    public bool Ind { get; init; }
    public bool IndNr { get; init; }
    public bool Huf { get; init; }
    public bool HufNr { get; init; }
    public bool Firm { get; init; }
    public bool Company { get; init; }
    public bool CompanyNr { get; init; }
    public bool Coop { get; init; }
    public int SortId { get; init; }
    public int AyId { get; init; }
    public int AyId2 { get; init; }
}

public sealed record TdsEntriesSectionDto
{
    public string? Section { get; init; }
    public int PayCode { get; init; }
    public string? Name { get; init; }
    public int Limit { get; init; }
    public string? FormName { get; init; }
    public string? NewSection { get; init; }
}

public sealed record CheckPeriodDto
{
    public int Id { get; init; }
    public int Quarter { get; init; }
    public int Month { get; init; }
    public int AyId { get; init; }
}

public sealed record TdsAoMasterDto
{
    public int AoCode { get; init; }
    public string? AoIn { get; init; }
    public string? LAoIn { get; init; }
    public string? Name { get; init; }
    public string? Add1 { get; init; }
    public string? Add2 { get; init; }
    public string? Add3 { get; init; }
    public string? Add4 { get; init; }
    public string? City { get; init; }
    public int StateCode { get; init; }
    public int Pin { get; init; }
    public string? Std { get; init; }
    public string? Phone { get; init; }
    public string? Email { get; init; }
    public string? APerson { get; init; }
    public string? ADesig { get; init; }
    public string? Cat { get; init; }
    public string? LatAoCat { get; init; }
    public string? RAdd1 { get; init; }
    public string? RAdd2 { get; init; }
    public string? RAdd3 { get; init; }
    public string? RAdd4 { get; init; }
    public string? RCity { get; init; }
    public int RStateCode { get; init; }
    public string? RPin { get; init; }
    public string? RStd { get; init; }
    public string? RPhone { get; init; }
    public string? REmail { get; init; }
    public string? RMobile { get; init; }
    public string? MinName { get; init; }
    public string? SMinName { get; init; }
    public string? SMinName2 { get; init; }
    public int PaoRegNo { get; init; }
    public string? StateName { get; init; }
    public string? Mobile { get; init; }
}

public sealed record ApplicationParamsDto
{
    public int Id { get; init; }
    public string? Name { get; init; }
    public string? Value { get; init; }
}

// ── Endpoints ─────────────────────────────────────────────────────────────────

public static class MastersEndpoints
{
    public static void MapMastersEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/masters").RequireAuthorization();

        // GET /api/masters/states
        grp.MapGet("/states", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select id, code, name from state order by name";
            var rows = await conn.QueryAsync<StateDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListStates");

        // GET /api/masters/countries
        grp.MapGet("/countries", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select id, code, name from country order by name";
            var rows = await conn.QueryAsync<CountryDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListCountries");

        // GET /api/masters/districts?stateCode=
        grp.MapGet("/districts", async (IDbConnectionFactory db, CancellationToken ct, int? stateCode) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (stateCode.HasValue)
            {
                sql = "select id, code, statecode, name from district where statecode = @stateCode order by name";
                param = new { stateCode = stateCode.Value };
            }
            else
            {
                sql = "select id, code, statecode, name from district order by name";
                param = null;
            }
            var rows = await conn.QueryAsync<DistrictDto>(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListDistricts");

        // GET /api/masters/postoffices
        grp.MapGet("/postoffices", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select id, code, name from postoffice order by name";
            var rows = await conn.QueryAsync<PostOfficeDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListPostOffices");

        // GET /api/masters/subdistricts
        grp.MapGet("/subdistricts", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select id, code, name from subdistrict order by name";
            var rows = await conn.QueryAsync<SubDistrictDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListSubDistricts");

        // GET /api/masters/pincode?pincode=  (no pincode -> ALL rows; desktop loads all at startup)
        grp.MapGet("/pincode", async (IDbConnectionFactory db, CancellationToken ct, double? pincode) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (pincode.HasValue)
            {
                sql = "select * from pincode where pincode = @pincode";
                param = new { pincode = pincode.Value };
            }
            else
            {
                sql = "select * from pincode";
                param = null;
            }
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("LookupPincode");

        // GET /api/masters/aymaster
        grp.MapGet("/aymaster", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            // dates are stored as dd/MM/yyyy varchar; parse to DateTime so the desktop's
            // AyMaster (DateTime fields) deserializes without a format error.
            static DateTime D(string s) => DateTime.TryParseExact(s, "dd/MM/yyyy",
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None, out var dt) ? dt : DateTime.MinValue;

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select id, ayid, name, startdt, enddt,
                                        nonbusinc, businc, auditcase, compcase, case94e,
                                        advinst1, advinst2, advinst3, advinst4,
                                        updnonbusinc, updbusinc, updauditcase, updcompcase, updcase94e
                                 from aymaster";
            var rows = await conn.QueryAsync<AyMasterDto>(new CommandDefinition(sql, cancellationToken: ct));
            var outp = new List<AyMasterOut>();
            foreach (var r in rows)
                outp.Add(new AyMasterOut(r.Id, r.AyId, r.Name,
                    D(r.StartDt), D(r.EndDt), D(r.NonBusInc), D(r.BusInc), D(r.AuditCase),
                    D(r.CompCase), D(r.Case94E), D(r.AdvInst1), D(r.AdvInst2), D(r.AdvInst3), D(r.AdvInst4),
                    D(r.UpdNonBusInc), D(r.UpdBusInc), D(r.UpdAuditCase), D(r.UpdCompCase), D(r.UpdCase94E)));
            return Results.Ok(outp);
        }).WithName("ListAyMaster");

        // GET /api/masters/tdsnatures
        grp.MapGet("/tdsnatures", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select code, particular from tdsnature";
            var rows = await conn.QueryAsync<TdsNatureDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTdsNatures");

        // GET /api/masters/tdsrates?ayId=
        grp.MapGet("/tdsrates", async (IDbConnectionFactory db, CancellationToken ct, int? ayId) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (ayId.HasValue)
            {
                sql = @"select ayid, tsid, paycode, rate, surch, ""limit""
                        from tdsrate where ayid = @ayId";
                param = new { ayId = ayId.Value };
            }
            else
            {
                sql = @"select ayid, tsid, paycode, rate, surch, ""limit"" from tdsrate";
                param = null;
            }
            var rows = await conn.QueryAsync<TdsRateDto>(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTdsRates");

        // GET /api/masters/tdsded80?ayId=
        grp.MapGet("/tdsded80", async (IDbConnectionFactory db, CancellationToken ct, int? ayId) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (ayId.HasValue)
            {
                sql = @"select ded80id, dedsec, ded80name, ded80table,
                               label1, label2, label3, label4, label5,
                               label6, label7, label8, label9, label10,
                               dedtype, pdedid, section, short,
                               ind, indnr, huf, hufnr, firm, company, companynr, coop,
                               sortid, ayid, ayid2
                        from tdsded80 where ayid = @ayId order by sortid";
                param = new { ayId = ayId.Value };
            }
            else
            {
                sql = @"select ded80id, dedsec, ded80name, ded80table,
                               label1, label2, label3, label4, label5,
                               label6, label7, label8, label9, label10,
                               dedtype, pdedid, section, short,
                               ind, indnr, huf, hufnr, firm, company, companynr, coop,
                               sortid, ayid, ayid2
                        from tdsded80 order by sortid";
                param = null;
            }
            var rows = await conn.QueryAsync<Tdsded80Dto>(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTdsDed80");

        // GET /api/masters/tdsentriessections?formName=
        grp.MapGet("/tdsentriessections", async (IDbConnectionFactory db, CancellationToken ct, string? formName) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (!string.IsNullOrWhiteSpace(formName))
            {
                sql = @"select section, paycode, name, ""limit"", formname, newsection
                        from tdsentriessection where formname = @formName";
                param = new { formName };
            }
            else
            {
                sql = @"select section, paycode, name, ""limit"", formname, newsection
                        from tdsentriessection";
                param = null;
            }
            var rows = await conn.QueryAsync<TdsEntriesSectionDto>(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTdsEntriesSections");

        // GET /api/masters/checkperiods?ayId=
        grp.MapGet("/checkperiods", async (IDbConnectionFactory db, CancellationToken ct, int? ayId) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            string sql;
            object? param;
            if (ayId.HasValue)
            {
                sql = "select id, quarter, month, ayid from check_period where ayid = @ayId";
                param = new { ayId = ayId.Value };
            }
            else
            {
                sql = "select id, quarter, month, ayid from check_period";
                param = null;
            }
            var rows = await conn.QueryAsync<CheckPeriodDto>(
                new CommandDefinition(sql, param, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListCheckPeriods");

        // GET /api/masters/tdsaomasters
        grp.MapGet("/tdsaomasters", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select aocode, aoin, laoin, name, add1, add2, add3, add4,
                                        city, statecode, pin, std, phone, email,
                                        aperson, adesig, cat, lataocat,
                                        radd1, radd2, radd3, radd4, rcity, rstatecode,
                                        rpin, rstd, rphone, remail, rmobile,
                                        minname, sminname, sminname2, paoregno, statename, mobile
                                 from tdsaomaster";
            var rows = await conn.QueryAsync<TdsAoMasterDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTdsAoMasters");

        // GET /api/masters/applicationparams
        // NOTE: applicationparams is a single shared (non-RLS) table. The licence
        // service stores per-key AES blobs here as rows named 'auth' / 'auth:<KEY>'.
        // Those must NEVER be returned to clients (in Online mode that would leak every
        // firm's encrypted licence blob cross-tenant), so they are filtered out here.
        grp.MapGet("/applicationparams", async (IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql =
                "select id, name, value from applicationparams where name <> 'auth' and name not like 'auth:%'";
            var rows = await conn.QueryAsync<ApplicationParamsDto>(
                new CommandDefinition(sql, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListApplicationParams");

        // PUT /api/masters/applicationparams  — upsert a single config row {name, value}.
        // This was MISSING: the desktop (ApplicationParamsBal.UpdateApplicationParams,
        // used by Lock Tax Year) PUTs here, but only a GET existed, so the call 404'd and
        // surfaced as a generic ApiException ("SmartTds could not continue"). Same shared
        // master-DB scope as the GET. The 'auth'/'auth:*' licence blobs are protected:
        // clients may not create or overwrite them through this endpoint.
        grp.MapPut("/applicationparams", async (ApplicationParamsDto dto, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Name))
                return Results.BadRequest("name is required");

            var name = dto.Name.Trim();
            if (string.Equals(name, "auth", StringComparison.OrdinalIgnoreCase)
                || name.StartsWith("auth:", StringComparison.OrdinalIgnoreCase))
                return Results.StatusCode(403);

            using var conn = await db.OpenMasterAsync(ct);
            var affected = await conn.ExecuteAsync(new CommandDefinition(
                "update applicationparams set value = @Value where name = @Name",
                new { Name = name, dto.Value }, cancellationToken: ct));
            if (affected == 0)
                await conn.ExecuteAsync(new CommandDefinition(
                    "insert into applicationparams (name, value) values (@Name, @Value)",
                    new { Name = name, dto.Value }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpsertApplicationParams");
    }
}
