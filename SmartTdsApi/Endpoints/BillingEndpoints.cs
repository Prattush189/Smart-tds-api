using System.Data;
using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ─────────────────────────────────────────────────────────────────────────
// Billing endpoints (master DB). Replaces the legacy MasterDbTdsDataSet +
// inline MAX+1 bill-number generation. Request DTO property names match the
// MasterEntities entities 1:1 so the BAL can POST/PUT the entity directly.
// Identity / server-owned PK columns are excluded from write DTOs.
//
// Tables: billhead (pk=id), billdetails (pk=id, no isdeleted -> hard delete),
//         billreceipts (pk=id), billmast (legacy, pk=billid),
//         billreceipt (legacy, pk=receiptno).
// ─────────────────────────────────────────────────────────────────────────

/// <summary>Writable billhead columns (matches MasterEntities.BillHead; id is identity).</summary>
public sealed record BillHeadReq
{
    public int subCode { get; init; }
    public int ayId { get; init; }
    public int? periodId { get; init; }
    public int conscode { get; init; }
    public int billNo { get; init; }
    public DateTime billDt { get; init; }
    public int pos { get; init; }
    public double totAmt { get; init; }
    public double amtReceived { get; init; }
    public double amtDisc { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
}

/// <summary>Writable billdetails columns (matches MasterEntities.BillDetails; id is identity).</summary>
public sealed record BillDetailsReq
{
    public int billId { get; init; }
    public string? description { get; init; }
    public double? prodCode { get; init; }
    public string? unit { get; init; }
    public double qty { get; init; }
    public double value { get; init; }
    public double discount { get; init; }
    public double taxableValue { get; init; }
    public double rateMain { get; init; }
    public double amtIgst { get; init; }
    public double amtCgst { get; init; }
    public double amtSgst { get; init; }
    public double amtCess { get; init; }
    public double totAmount { get; init; }
}

/// <summary>Writable billreceipts columns (matches MasterEntities.BillReceipts; id is identity).</summary>
public sealed record BillReceiptsReq
{
    public int ayId { get; init; }
    public int billId { get; init; }
    public int receiptNo { get; init; }
    public DateTime receiptDt { get; init; }
    public double amtReceived { get; init; }
    public double amtDisc { get; init; }
    public string? mode { get; init; }
    public string? instrumentNo { get; init; }
    public DateTime? instrumentDt { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
}

/// <summary>Writable billmast (legacy) columns (matches MasterEntities.Billmast; billid is identity).</summary>
public sealed record BillmastReq
{
    public string? date { get; init; }
    public int subcode { get; init; }
    public int billno { get; init; }
    public string? p1 { get; init; } public double p1amt { get; init; }
    public string? p2 { get; init; } public double p2amt { get; init; }
    public string? p3 { get; init; } public double p3amt { get; init; }
    public string? p4 { get; init; } public double p4amt { get; init; }
    public string? p5 { get; init; } public double p5amt { get; init; }
    public string? p6 { get; init; } public double p6amt { get; init; }
    public string? p7 { get; init; } public double p7amt { get; init; }
    public string? p8 { get; init; } public double p8amt { get; init; }
    public string? p9 { get; init; } public double p9amt { get; init; }
    public string? p10 { get; init; } public double p10amt { get; init; }
    public double stax { get; init; }
    public double tamt { get; init; }
    public double sperc { get; init; }
    public double ramt { get; init; }
    public int ayid { get; init; }
    public int conscode { get; init; }
    public double damt { get; init; }
    public bool receipt { get; init; }
    public int grpcode { get; init; }
}

/// <summary>Writable billreceipt (legacy) columns. receiptno is identity.</summary>
public sealed record BillReceiptReq
{
    public string? date { get; init; }
    public int subcode { get; init; }
    public int billno { get; init; }
    public double amount { get; init; }
    public string? mode { get; init; }
    public string? number { get; init; }
    public string? billdate { get; init; }
    public int ayid { get; init; }
    public int conscode { get; init; }
    public double discount { get; init; }
    public int billid { get; init; }
    public int userid { get; init; }
    public string? lastupdate { get; init; }
}

public static class BillingEndpoints
{
    public static void MapBillingEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api").RequireAuthorization();

        MapBillHead(grp);
        MapBillDetails(grp);
        MapBillReceipts(grp);
        MapBillmast(grp);
        MapBillReceipt(grp);
    }

    // ───────────────────────────── BILLHEAD ─────────────────────────────
    // Firm-scoped via conscode (the firm's consultant). billdt is a real date
    // column; the entity DateTime deserializes from ISO fine.
    private static void MapBillHead(RouteGroupBuilder grp)
    {
        const string Columns =
            @"subcode, ayid, periodid, conscode, billno, billdt, pos, totamt, amtreceived,
              amtdisc, createdby, createdon, modifiedby, modifiedon, isdeleted";

        const string Values =
            @"@subCode, @ayId, @periodId, @conscode, @billNo, @billDt, @pos, @totAmt, @amtReceived,
              @amtDisc, @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted";

        const string Set =
            @"subcode=@subCode, ayid=@ayId, periodid=@periodId, conscode=@conscode, billno=@billNo,
              billdt=@billDt, pos=@pos, totamt=@totAmt, amtreceived=@amtReceived, amtdisc=@amtDisc,
              createdby=@CreatedBy, createdon=@CreatedOn, modifiedby=@ModifiedBy,
              modifiedon=@ModifiedOn, isdeleted=@IsDeleted";

        // GET /api/billhead?subCode=&ayId=&conscode= — full rows, undeleted only.
        // ayId/conscode required; subCode optional (0/omitted => all for that firm/year).
        grp.MapGet("/billhead", async (int? subCode, int ayId, int conscode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from billhead
                                 where ayid = @ayId and conscode = @conscode and isdeleted = false
                                   and (@subCode is null or @subCode = 0 or subcode = @subCode)
                                 order by billno desc";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode, ayId, conscode }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBillHead");

        // GET /api/billhead/pending?subCode= — pending (unpaid) bills for a firm.
        // "Pending" = outstanding balance > 0, i.e. (totamt-amtreceived-amtdisc) > 0,
        // across all years; undeleted only. (Replaces the legacy pending-bills query.)
        grp.MapGet("/billhead/pending", async (int subCode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from billhead
                                 where subcode = @subCode and isdeleted = false
                                   and (coalesce(totamt,0) - coalesce(amtreceived,0) - coalesce(amtdisc,0)) > 0
                                 order by billno desc";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListPendingBillHead");

        // GET /api/billhead/nextno?conscode=&ayId= — next bill number, race-safe.
        // Advisory xact lock serializes concurrent number allocation per (conscode, ay).
        grp.MapGet("/billhead/nextno", async (int conscode, int ayId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            using var tx = conn.BeginTransaction();
            await conn.ExecuteAsync(new CommandDefinition(
                "select pg_advisory_xact_lock(hashtext(@key))",
                new { key = $"billno:{conscode}:{ayId}" }, tx, cancellationToken: ct));
            var next = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                @"select coalesce(max(billno),0)+1 from billhead
                  where conscode = @conscode and ayid = @ayId and isdeleted = false",
                new { conscode, ayId }, tx, cancellationToken: ct));
            tx.Commit();
            return Results.Ok(new { billNo = next });
        }).WithName("NextBillHeadNo");

        // GET /api/billhead/{id}
        grp.MapGet("/billhead/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billhead where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBillHead");

        // POST /api/billhead — insert; returns { id }.
        grp.MapPost("/billhead", async (BillHeadReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into billhead ({Columns}) values ({Values}) returning id";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BillHeadParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBillHead");

        // PUT /api/billhead/{id}
        grp.MapPut("/billhead/{id:int}", async (int id, BillHeadReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update billhead set {Set} where id = @id";
            var p = BillHeadParams(body);
            p.Add("id", id);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBillHead");

        // DELETE /api/billhead/{id} — hard delete (permanent). Removes the bill's
        // receipts first (billreceipts FK has no cascade); billdetails are removed
        // automatically by their ON DELETE CASCADE FK.
        grp.MapDelete("/billhead/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"delete from billreceipts where billid = @id;
                                 delete from billhead     where id = @id;";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBillHead");
    }

    // ───────────────────────────── BILLDETAILS ─────────────────────────────
    // Child of billhead (billid FK). No isdeleted column -> hard delete.
    private static void MapBillDetails(RouteGroupBuilder grp)
    {
        const string Columns =
            @"billid, description, prodcode, unit, qty, value, discount, taxablevalue, ratemain,
              amtigst, amtcgst, amtsgst, amtcess, totamount";

        const string Values =
            @"@billId, @description, @prodCode, @unit, @qty, @value, @discount, @taxableValue, @rateMain,
              @amtIgst, @amtCgst, @amtSgst, @amtCess, @totAmount";

        const string Set =
            @"billid=@billId, description=@description, prodcode=@prodCode, unit=@unit, qty=@qty,
              value=@value, discount=@discount, taxablevalue=@taxableValue, ratemain=@rateMain,
              amtigst=@amtIgst, amtcgst=@amtCgst, amtsgst=@amtSgst, amtcess=@amtCess, totamount=@totAmount";

        // GET /api/billdetails?billId=
        grp.MapGet("/billdetails", async (int billId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billdetails where billid = @billId order by id";
            var rows = await conn.QueryAsync(new CommandDefinition(sql, new { billId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBillDetails");

        // GET /api/billdetails/{id}
        grp.MapGet("/billdetails/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billdetails where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBillDetails");

        // POST /api/billdetails — insert; returns { id }.
        grp.MapPost("/billdetails", async (BillDetailsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into billdetails ({Columns}) values ({Values}) returning id";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BillDetailsParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBillDetails");

        // PUT /api/billdetails/{id}
        grp.MapPut("/billdetails/{id:int}", async (int id, BillDetailsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update billdetails set {Set} where id = @id";
            var p = BillDetailsParams(body);
            p.Add("id", id);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBillDetails");

        // DELETE /api/billdetails/{id} — hard delete (no isdeleted column).
        grp.MapDelete("/billdetails/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from billdetails where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBillDetails");
    }

    // ───────────────────────────── BILLRECEIPTS ─────────────────────────────
    // Child of billhead (billid). receiptdt/instrumentdt are real date columns.
    private static void MapBillReceipts(RouteGroupBuilder grp)
    {
        const string Columns =
            @"ayid, billid, receiptno, receiptdt, amtreceived, amtdisc, mode, instrumentno,
              instrumentdt, createdby, createdon, modifiedby, modifiedon, isdeleted";

        const string Values =
            @"@ayId, @billId, @receiptNo, @receiptDt, @amtReceived, @amtDisc, @mode, @instrumentNo,
              @instrumentDt, @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted";

        const string Set =
            @"ayid=@ayId, billid=@billId, receiptno=@receiptNo, receiptdt=@receiptDt,
              amtreceived=@amtReceived, amtdisc=@amtDisc, mode=@mode, instrumentno=@instrumentNo,
              instrumentdt=@instrumentDt, createdby=@CreatedBy, createdon=@CreatedOn,
              modifiedby=@ModifiedBy, modifiedon=@ModifiedOn, isdeleted=@IsDeleted";

        // GET /api/billreceipts?billId=&ayId= — full rows, undeleted only.
        // billId optional (0/omitted => all); ayId optional (0/omitted => all years).
        grp.MapGet("/billreceipts", async (int? billId, int? ayId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from billreceipts
                                 where isdeleted = false
                                   and (@billId is null or @billId = 0 or billid = @billId)
                                   and (@ayId is null or @ayId = 0 or ayid = @ayId)
                                 order by receiptno";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { billId, ayId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBillReceipts");

        // GET /api/billreceipts/lastno?dateFrm=&dateTo= — max receiptno in a date range.
        // receiptdt is a real date column; dateFrm/dateTo are ISO date strings.
        // Returns { receiptNo: <max or 0> } (read-only — no advisory lock needed).
        grp.MapGet("/billreceipts/lastno", async (string? dateFrm, string? dateTo, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select coalesce(max(receiptno),0) from billreceipts
                                 where isdeleted = false
                                   and (@dateFrm is null or @dateFrm = '' or receiptdt >= cast(@dateFrm as date))
                                   and (@dateTo  is null or @dateTo  = '' or receiptdt <= cast(@dateTo  as date))";
            var max = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, new { dateFrm, dateTo }, cancellationToken: ct));
            return Results.Ok(new { receiptNo = max });
        }).WithName("LastBillReceiptNo");

        // GET /api/billreceipts/{id}
        grp.MapGet("/billreceipts/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billreceipts where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBillReceipts");

        // POST /api/billreceipts — insert; returns { id }.
        grp.MapPost("/billreceipts", async (BillReceiptsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into billreceipts ({Columns}) values ({Values}) returning id";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BillReceiptsParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBillReceipts");

        // PUT /api/billreceipts/{id}
        grp.MapPut("/billreceipts/{id:int}", async (int id, BillReceiptsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update billreceipts set {Set} where id = @id";
            var p = BillReceiptsParams(body);
            p.Add("id", id);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBillReceipts");

        // DELETE /api/billreceipts/{id} — soft delete.
        grp.MapDelete("/billreceipts/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from billreceipts where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBillReceipts");
    }

    // ───────────────────────── BILLMAST (legacy) ─────────────────────────
    // pk=billid. `date` is varchar (non-reserved in PG, ok unquoted);
    // `receipt` is boolean. Firm-scoped via conscode where requested.
    private static void MapBillmast(RouteGroupBuilder grp)
    {
        const string Columns =
            @"date, subcode, billno, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10,
              p1amt, p2amt, p3amt, p4amt, p5amt, p6amt, p7amt, p8amt, p9amt, p10amt,
              stax, tamt, sperc, ramt, ayid, conscode, damt, receipt, grpcode";

        const string Values =
            @"@date, @subcode, @billno, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10,
              @p1amt, @p2amt, @p3amt, @p4amt, @p5amt, @p6amt, @p7amt, @p8amt, @p9amt, @p10amt,
              @stax, @tamt, @sperc, @ramt, @ayid, @conscode, @damt, @receipt, @grpcode";

        const string Set =
            @"date=@date, subcode=@subcode, billno=@billno, p1=@p1, p2=@p2, p3=@p3, p4=@p4, p5=@p5,
              p6=@p6, p7=@p7, p8=@p8, p9=@p9, p10=@p10, p1amt=@p1amt, p2amt=@p2amt, p3amt=@p3amt,
              p4amt=@p4amt, p5amt=@p5amt, p6amt=@p6amt, p7amt=@p7amt, p8amt=@p8amt, p9amt=@p9amt,
              p10amt=@p10amt, stax=@stax, tamt=@tamt, sperc=@sperc, ramt=@ramt, ayid=@ayid,
              conscode=@conscode, damt=@damt, receipt=@receipt, grpcode=@grpcode";

        // GET /api/billmast?subCode=&ayId=&conscode= — full rows, undeleted only.
        // All three optional (0/omitted => not filtered) so the BAL's GetAll(ayId) and
        // GetBySubcode(subcode) both map here.
        grp.MapGet("/billmast", async (int? subCode, int? ayId, int? conscode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from billmast
                                 where isdeleted = false
                                   and (@subCode is null or @subCode = 0 or subcode = @subCode)
                                   and (@ayId is null or @ayId = 0 or ayid = @ayId)
                                   and (@conscode is null or @conscode = 0 or conscode = @conscode)
                                 order by billid";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode, ayId, conscode }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBillmast");

        // GET /api/billmast/nextno?subCode=&ayId= — next bill number, race-safe.
        grp.MapGet("/billmast/nextno", async (int subCode, int ayId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            using var tx = conn.BeginTransaction();
            await conn.ExecuteAsync(new CommandDefinition(
                "select pg_advisory_xact_lock(hashtext(@key))",
                new { key = $"billmastno:{subCode}:{ayId}" }, tx, cancellationToken: ct));
            var next = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                @"select coalesce(max(billno),0)+1 from billmast
                  where subcode = @subCode and ayid = @ayId and isdeleted = false",
                new { subCode, ayId }, tx, cancellationToken: ct));
            tx.Commit();
            return Results.Ok(new { billNo = next });
        }).WithName("NextBillmastNo");

        // GET /api/billmast/{billId}
        grp.MapGet("/billmast/{billId:int}", async (int billId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billmast where billid = @billId";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { billId }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBillmast");

        // POST /api/billmast — insert; returns { id } = new billid.
        grp.MapPost("/billmast", async (BillmastReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into billmast ({Columns}) values ({Values}) returning billid";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BillmastParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBillmast");

        // PUT /api/billmast/{billId}
        grp.MapPut("/billmast/{billId:int}", async (int billId, BillmastReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update billmast set {Set} where billid = @billId";
            var p = BillmastParams(body);
            p.Add("billId", billId);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBillmast");

        // DELETE /api/billmast/{billId} — soft delete (schema has isdeleted).
        grp.MapDelete("/billmast/{billId:int}", async (int billId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from billmast where billid = @billId";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { billId }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBillmast");
    }

    // ───────────────────────── BILLRECEIPT (legacy) ─────────────────────────
    // pk=receiptno. Columns mode/number/date are non-reserved in PG (ok unquoted).
    private static void MapBillReceipt(RouteGroupBuilder grp)
    {
        const string Columns =
            @"date, subcode, billno, amount, mode, number, billdate, ayid, conscode,
              discount, billid, userid, lastupdate";

        const string Values =
            @"@date, @subcode, @billno, @amount, @mode, @number, @billdate, @ayid, @conscode,
              @discount, @billid, @userid, @lastupdate";

        const string Set =
            @"date=@date, subcode=@subcode, billno=@billno, amount=@amount, mode=@mode, number=@number,
              billdate=@billdate, ayid=@ayid, conscode=@conscode, discount=@discount, billid=@billid,
              userid=@userid, lastupdate=@lastupdate";

        // GET /api/billreceipt?subCode=&billId= — full rows, undeleted only.
        // Both optional (0/omitted => not filtered).
        grp.MapGet("/billreceipt", async (int? subCode, int? billId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from billreceipt
                                 where isdeleted = false
                                   and (@subCode is null or @subCode = 0 or subcode = @subCode)
                                   and (@billId is null or @billId = 0 or billid = @billId)
                                 order by receiptno";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode, billId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBillReceipt");

        // GET /api/billreceipt/{receiptNo}
        grp.MapGet("/billreceipt/{receiptNo:int}", async (int receiptNo, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from billreceipt where receiptno = @receiptNo";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { receiptNo }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBillReceipt");

        // POST /api/billreceipt — insert; returns { id } = new receiptno.
        grp.MapPost("/billreceipt", async (BillReceiptReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into billreceipt ({Columns}) values ({Values}) returning receiptno";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BillReceiptParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBillReceipt");

        // PUT /api/billreceipt/{receiptNo}
        grp.MapPut("/billreceipt/{receiptNo:int}", async (int receiptNo, BillReceiptReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update billreceipt set {Set} where receiptno = @receiptNo";
            var p = BillReceiptParams(body);
            p.Add("receiptNo", receiptNo);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBillReceipt");

        // DELETE /api/billreceipt/{receiptNo} — soft delete.
        grp.MapDelete("/billreceipt/{receiptNo:int}", async (int receiptNo, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from billreceipt where receiptno = @receiptNo";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { receiptNo }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBillReceipt");
    }

    // ───────────────────────────── param builders ─────────────────────────────
    private static DynamicParameters BillHeadParams(BillHeadReq b)
    {
        var p = new DynamicParameters();
        p.Add("subCode", b.subCode);
        p.Add("ayId", b.ayId);
        p.Add("periodId", b.periodId);
        p.Add("conscode", b.conscode);
        p.Add("billNo", b.billNo);
        p.Add("billDt", b.billDt);
        p.Add("pos", b.pos);
        p.Add("totAmt", b.totAmt);
        p.Add("amtReceived", b.amtReceived);
        p.Add("amtDisc", b.amtDisc);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        return p;
    }

    private static DynamicParameters BillDetailsParams(BillDetailsReq b)
    {
        var p = new DynamicParameters();
        p.Add("billId", b.billId);
        p.Add("description", b.description);
        p.Add("prodCode", b.prodCode);
        p.Add("unit", b.unit);
        p.Add("qty", b.qty);
        p.Add("value", b.value);
        p.Add("discount", b.discount);
        p.Add("taxableValue", b.taxableValue);
        p.Add("rateMain", b.rateMain);
        p.Add("amtIgst", b.amtIgst);
        p.Add("amtCgst", b.amtCgst);
        p.Add("amtSgst", b.amtSgst);
        p.Add("amtCess", b.amtCess);
        p.Add("totAmount", b.totAmount);
        return p;
    }

    private static DynamicParameters BillReceiptsParams(BillReceiptsReq b)
    {
        var p = new DynamicParameters();
        p.Add("ayId", b.ayId);
        p.Add("billId", b.billId);
        p.Add("receiptNo", b.receiptNo);
        p.Add("receiptDt", b.receiptDt);
        p.Add("amtReceived", b.amtReceived);
        p.Add("amtDisc", b.amtDisc);
        p.Add("mode", b.mode);
        p.Add("instrumentNo", b.instrumentNo);
        p.Add("instrumentDt", b.instrumentDt);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        return p;
    }

    private static DynamicParameters BillmastParams(BillmastReq b)
    {
        var p = new DynamicParameters();
        p.Add("date", b.date);
        p.Add("subcode", b.subcode);
        p.Add("billno", b.billno);
        p.Add("p1", b.p1); p.Add("p1amt", b.p1amt);
        p.Add("p2", b.p2); p.Add("p2amt", b.p2amt);
        p.Add("p3", b.p3); p.Add("p3amt", b.p3amt);
        p.Add("p4", b.p4); p.Add("p4amt", b.p4amt);
        p.Add("p5", b.p5); p.Add("p5amt", b.p5amt);
        p.Add("p6", b.p6); p.Add("p6amt", b.p6amt);
        p.Add("p7", b.p7); p.Add("p7amt", b.p7amt);
        p.Add("p8", b.p8); p.Add("p8amt", b.p8amt);
        p.Add("p9", b.p9); p.Add("p9amt", b.p9amt);
        p.Add("p10", b.p10); p.Add("p10amt", b.p10amt);
        p.Add("stax", b.stax);
        p.Add("tamt", b.tamt);
        p.Add("sperc", b.sperc);
        p.Add("ramt", b.ramt);
        p.Add("ayid", b.ayid);
        p.Add("conscode", b.conscode);
        p.Add("damt", b.damt);
        p.Add("receipt", b.receipt);
        p.Add("grpcode", b.grpcode);
        return p;
    }

    private static DynamicParameters BillReceiptParams(BillReceiptReq b)
    {
        var p = new DynamicParameters();
        p.Add("date", b.date);
        p.Add("subcode", b.subcode);
        p.Add("billno", b.billno);
        p.Add("amount", b.amount);
        p.Add("mode", b.mode);
        p.Add("number", b.number);
        p.Add("billdate", b.billdate);
        p.Add("ayid", b.ayid);
        p.Add("conscode", b.conscode);
        p.Add("discount", b.discount);
        p.Add("billid", b.billid);
        p.Add("userid", b.userid);
        p.Add("lastupdate", b.lastupdate);
        return p;
    }
}
