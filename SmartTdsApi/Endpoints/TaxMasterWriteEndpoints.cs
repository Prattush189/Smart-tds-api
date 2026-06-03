using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ── Request DTOs (writable columns; property names match MasterEntities.*) ───────

public sealed record TdsNatureReq
{
    public int code { get; init; }
    public string? particular { get; init; }
}

public sealed record TdsRateReq
{
    public int ayid { get; init; }
    public int tsId { get; init; }
    public int PayCode { get; init; }
    public double Rate { get; init; }
    public double Surch { get; init; }
    public int Limit { get; init; }
}

public sealed record Tdsded80Req
{
    public int ded80id { get; init; }
    public string? dedsec { get; init; }
    public string? ded80name { get; init; }
    public string? ded80table { get; init; }
    public string? label1 { get; init; }
    public string? label2 { get; init; }
    public string? label3 { get; init; }
    public string? label4 { get; init; }
    public string? label5 { get; init; }
    public string? label6 { get; init; }
    public string? label7 { get; init; }
    public string? label8 { get; init; }
    public string? label9 { get; init; }
    public string? label10 { get; init; }
    public string? dedtype { get; init; }
    public int pdedid { get; init; }
    public string? section { get; init; }
    public string? shortName { get; init; }
    public bool ind { get; init; }
    public bool indnr { get; init; }
    public bool huf { get; init; }
    public bool hufnr { get; init; }
    public bool firm { get; init; }
    public bool company { get; init; }
    public bool companynr { get; init; }
    public bool coop { get; init; }
    public int sortid { get; init; }
    public int ayid { get; init; }
    public int ayid2 { get; init; }
}

public sealed record TdsEntriesSectionReq
{
    public string? Section { get; init; }
    public int Paycode { get; init; }
    public string? Name { get; init; }
    public int Limit { get; init; }
    public string? FormName { get; init; }
    public string? NewSection { get; init; }
}

public sealed record CheckPeriodReq
{
    public int quarter { get; init; }
    public int month { get; init; }
    public int ayid { get; init; }
}

public sealed record TdsAoMasterReq
{
    public string? aoin { get; init; }
    public string? laoin { get; init; }
    public string? name { get; init; }
    public string? add1 { get; init; }
    public string? add2 { get; init; }
    public string? add3 { get; init; }
    public string? add4 { get; init; }
    public string? city { get; init; }
    public int statecode { get; init; }
    public int pin { get; init; }
    public string? std { get; init; }
    public string? phone { get; init; }
    public string? email { get; init; }
    public string? aperson { get; init; }
    public string? adesig { get; init; }
    public string? cat { get; init; }
    public string? lataocat { get; init; }
    public string? radd1 { get; init; }
    public string? radd2 { get; init; }
    public string? radd3 { get; init; }
    public string? radd4 { get; init; }
    public string? rcity { get; init; }
    public int rstatecode { get; init; }
    public string? rpin { get; init; }
    public string? rstd { get; init; }
    public string? rphone { get; init; }
    public string? remail { get; init; }
    public string? rmobile { get; init; }
    public string? minname { get; init; }
    public string? sminname { get; init; }
    public string? sminname2 { get; init; }
    public int paoregno { get; init; }
    public string? statename { get; init; }
    public string? mobile { get; init; }
}

// ── Endpoints ─────────────────────────────────────────────────────────────────

/// <summary>
/// Write side (insert/update/delete) for the tax-master tables. Reads live in
/// MastersEndpoints (/api/masters/...); writes are grouped here under
/// /api/taxmaster/... All run against the master DB, parameterized; inserts use
/// RETURNING the pk where a pk exists. The reserved column "limit" is quoted.
/// </summary>
public static class TaxMasterWriteEndpoints
{
    public static void MapTaxMasterWriteEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/taxmaster").RequireAuthorization();

        // ── tdsnature (pk: code, supplied by caller — not identity) ──────────────
        grp.MapPost("/tdsnatures", async (TdsNatureReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into tdsnature (code, particular)
                                 values (@code, @particular)
                                 returning code";
            var code = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql, new { body.code, body.particular }, cancellationToken: ct));
            return Results.Ok(new { code });
        }).WithName("CreateTdsNature");

        grp.MapPut("/tdsnatures/{code:int}", async (int code, TdsNatureReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "update tdsnature set particular = @particular where code = @code";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { code, body.particular }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateTdsNature");

        grp.MapDelete("/tdsnatures/{code:int}", async (int code, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from tdsnature where code = @code", new { code }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTdsNature");

        // ── tdsrate (no pk; identified by ayid+tsid+paycode; "limit" quoted) ─────
        grp.MapPost("/tdsrates", async (TdsRateReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into tdsrate (ayid, tsid, paycode, rate, surch, ""limit"")
                                 values (@ayid, @tsId, @PayCode, @Rate, @Surch, @Limit)";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { body.ayid, body.tsId, body.PayCode, body.Rate, body.Surch, body.Limit },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("CreateTdsRate");

        grp.MapPut("/tdsrates", async (TdsRateReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update tdsrate
                                 set rate = @Rate, surch = @Surch, ""limit"" = @Limit
                                 where ayid = @ayid and tsid = @tsId and paycode = @PayCode";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { body.ayid, body.tsId, body.PayCode, body.Rate, body.Surch, body.Limit },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateTdsRate");

        grp.MapDelete("/tdsrates", async (int ayId, int tsId, int payCode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from tdsrate where ayid = @ayId and tsid = @tsId and paycode = @payCode";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { ayId, tsId, payCode }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTdsRate");

        // ── tdsded80 (pk: ded80id identity; boolean cols) ────────────────────────
        grp.MapPost("/tdsded80", async (Tdsded80Req body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into tdsded80
                                   (dedsec, ded80name, ded80table,
                                    label1, label2, label3, label4, label5,
                                    label6, label7, label8, label9, label10,
                                    dedtype, pdedid, section, short,
                                    ind, indnr, huf, hufnr, firm, company, companynr, coop,
                                    sortid, ayid, ayid2)
                                 values
                                   (@dedsec, @ded80name, @ded80table,
                                    @label1, @label2, @label3, @label4, @label5,
                                    @label6, @label7, @label8, @label9, @label10,
                                    @dedtype, @pdedid, @section, @shortName,
                                    @ind, @indnr, @huf, @hufnr, @firm, @company, @companynr, @coop,
                                    @sortid, @ayid, @ayid2)
                                 returning ded80id";
            var ded80id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql, body, cancellationToken: ct));
            return Results.Ok(new { ded80id });
        }).WithName("CreateTdsDed80");

        grp.MapPut("/tdsded80/{ded80id:int}", async (int ded80id, Tdsded80Req body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update tdsded80 set
                                   dedsec = @dedsec, ded80name = @ded80name, ded80table = @ded80table,
                                   label1 = @label1, label2 = @label2, label3 = @label3, label4 = @label4, label5 = @label5,
                                   label6 = @label6, label7 = @label7, label8 = @label8, label9 = @label9, label10 = @label10,
                                   dedtype = @dedtype, pdedid = @pdedid, section = @section, short = @shortName,
                                   ind = @ind, indnr = @indnr, huf = @huf, hufnr = @hufnr, firm = @firm,
                                   company = @company, companynr = @companynr, coop = @coop,
                                   sortid = @sortid, ayid = @ayid, ayid2 = @ayid2
                                 where ded80id = @ded80id";
            await conn.ExecuteAsync(new CommandDefinition(
                sql,
                new
                {
                    ded80id, body.dedsec, body.ded80name, body.ded80table,
                    body.label1, body.label2, body.label3, body.label4, body.label5,
                    body.label6, body.label7, body.label8, body.label9, body.label10,
                    body.dedtype, body.pdedid, body.section, body.shortName,
                    body.ind, body.indnr, body.huf, body.hufnr, body.firm,
                    body.company, body.companynr, body.coop,
                    body.sortid, body.ayid, body.ayid2
                },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateTdsDed80");

        grp.MapDelete("/tdsded80/{ded80id:int}", async (int ded80id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from tdsded80 where ded80id = @ded80id", new { ded80id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTdsDed80");

        // ── tdsentriessection (no pk; identified by paycode; "limit" quoted) ─────
        grp.MapPost("/tdsentriessections", async (TdsEntriesSectionReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into tdsentriessection (section, paycode, name, ""limit"", formname, newsection)
                                 values (@Section, @Paycode, @Name, @Limit, @FormName, @NewSection)";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { body.Section, body.Paycode, body.Name, body.Limit, body.FormName, body.NewSection },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("CreateTdsEntriesSection");

        grp.MapPut("/tdsentriessections/{paycode:int}", async (int paycode, TdsEntriesSectionReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update tdsentriessection
                                 set section = @Section, name = @Name, ""limit"" = @Limit,
                                     formname = @FormName, newsection = @NewSection
                                 where paycode = @paycode";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { paycode, body.Section, body.Name, body.Limit, body.FormName, body.NewSection },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateTdsEntriesSection");

        grp.MapDelete("/tdsentriessections/{paycode:int}", async (int paycode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from tdsentriessection where paycode = @paycode", new { paycode }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTdsEntriesSection");

        // ── check_period (pk: id identity) ───────────────────────────────────────
        grp.MapPost("/checkperiods", async (CheckPeriodReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into check_period (quarter, month, ayid)
                                 values (@quarter, @month, @ayid)
                                 returning id";
            var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql, new { body.quarter, body.month, body.ayid }, cancellationToken: ct));
            return Results.Ok(new { id });
        }).WithName("CreateCheckPeriod");

        grp.MapPut("/checkperiods/{id:int}", async (int id, CheckPeriodReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "update check_period set quarter = @quarter, month = @month, ayid = @ayid where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(
                sql, new { id, body.quarter, body.month, body.ayid }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateCheckPeriod");

        grp.MapDelete("/checkperiods/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from check_period where id = @id", new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteCheckPeriod");

        // ── tdsaomaster (pk: aocode identity) ────────────────────────────────────
        grp.MapPost("/tdsaomasters", async (TdsAoMasterReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into tdsaomaster
                                   (aoin, laoin, name, add1, add2, add3, add4, city, statecode, pin,
                                    std, phone, email, aperson, adesig, cat, lataocat,
                                    radd1, radd2, radd3, radd4, rcity, rstatecode, rpin, rstd, rphone, remail, rmobile,
                                    minname, sminname, sminname2, paoregno, statename, mobile)
                                 values
                                   (@aoin, @laoin, @name, @add1, @add2, @add3, @add4, @city, @statecode, @pin,
                                    @std, @phone, @email, @aperson, @adesig, @cat, @lataocat,
                                    @radd1, @radd2, @radd3, @radd4, @rcity, @rstatecode, @rpin, @rstd, @rphone, @remail, @rmobile,
                                    @minname, @sminname, @sminname2, @paoregno, @statename, @mobile)
                                 returning aocode";
            var aocode = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql, body, cancellationToken: ct));
            return Results.Ok(new { aocode });
        }).WithName("CreateTdsAoMaster");

        grp.MapPut("/tdsaomasters/{aocode:int}", async (int aocode, TdsAoMasterReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update tdsaomaster set
                                   aoin = @aoin, laoin = @laoin, name = @name,
                                   add1 = @add1, add2 = @add2, add3 = @add3, add4 = @add4,
                                   city = @city, statecode = @statecode, pin = @pin,
                                   std = @std, phone = @phone, email = @email,
                                   aperson = @aperson, adesig = @adesig, cat = @cat, lataocat = @lataocat,
                                   radd1 = @radd1, radd2 = @radd2, radd3 = @radd3, radd4 = @radd4,
                                   rcity = @rcity, rstatecode = @rstatecode, rpin = @rpin, rstd = @rstd,
                                   rphone = @rphone, remail = @remail, rmobile = @rmobile,
                                   minname = @minname, sminname = @sminname, sminname2 = @sminname2,
                                   paoregno = @paoregno, statename = @statename, mobile = @mobile
                                 where aocode = @aocode";
            await conn.ExecuteAsync(new CommandDefinition(
                sql,
                new
                {
                    aocode, body.aoin, body.laoin, body.name,
                    body.add1, body.add2, body.add3, body.add4,
                    body.city, body.statecode, body.pin,
                    body.std, body.phone, body.email,
                    body.aperson, body.adesig, body.cat, body.lataocat,
                    body.radd1, body.radd2, body.radd3, body.radd4,
                    body.rcity, body.rstatecode, body.rpin, body.rstd,
                    body.rphone, body.remail, body.rmobile,
                    body.minname, body.sminname, body.sminname2,
                    body.paoregno, body.statename, body.mobile
                },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateTdsAoMaster");

        grp.MapDelete("/tdsaomasters/{aocode:int}", async (int aocode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from tdsaomaster where aocode = @aocode", new { aocode }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTdsAoMaster");
    }
}
