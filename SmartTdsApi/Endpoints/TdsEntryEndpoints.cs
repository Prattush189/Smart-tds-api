using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

public sealed record TdsEntryDto
{
    public int Id { get; init; }
    public int? PayeeId { get; init; }
    public int? ChId { get; init; }
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public string? PayeeName { get; init; }
    public string? PayerName { get; init; }
    public int? Section { get; init; }
    public int? Nature { get; init; }
    public string? Descrp { get; init; }
    public string? DatePayment { get; init; }
    public string? DateDeduct { get; init; }
    public string? TypeDeduct { get; init; }
    public decimal? AmtPay { get; init; }
    public decimal? TdsRate { get; init; }
    public decimal? Surcharge { get; init; }
    public decimal? TdsDeduct { get; init; }
    public decimal? SurDeduct { get; init; }
    public decimal? Cess { get; init; }
    public string? DateDeposit { get; init; }
    public decimal? TotalTds2 { get; init; }
    public decimal? TdsDedLater { get; init; }
    public string? FormType { get; init; }
    public string? TdsApp { get; init; }
    public string? Ack15Ca { get; init; }
    public string? CertNo { get; init; }
    public string? DtValF { get; init; }
    public string? DtValT { get; init; }
    public string? DtPaying { get; init; }
    public string? DtComm { get; init; }
    public bool? EValid { get; init; }
    public decimal? ActualTds { get; init; }
    public decimal? ActualRate { get; init; }
    public decimal? ChInterest { get; init; }
    public decimal? ChTdsDep { get; init; }
    public string? DeductionCode { get; init; }
    public int? PCode { get; init; }
}

public static class TdsEntryEndpoints
{
    public static void MapTdsEntryEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tdsentries").RequireAuthorization();

        // GET /api/tdsentries?subCode=&ayId=&chId=&payeeId=
        // subCode + ayId select the firm/year; chId and payeeId are optional additional filters.
        grp.MapGet("/", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            int? chId,
            int? payeeId) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);

                var sql = new System.Text.StringBuilder(
                    @"select id, payeeid, chid, subcode, ayid,
                             payeename, payername, section, nature, descrp,
                             datepayment, datededuct, typededuct,
                             amtpay, tdsrate, surcharge, tdsdeduct, surdeduct, cess,
                             datedeposit, totaltds2, tdsdedlater,
                             formtype, tdsapp, ack15ca, certno,
                             dtvalf, dtvalt, dtpaying, dtcomm,
                             evalid, actualtds, actualrate,
                             chinterest, chtdsdep, deductioncode, pcode
                      from tdsentry
                      where subcode = @subCode and ayid = @ayId");

                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);

                if (chId.HasValue)
                {
                    sql.Append(" and chid = @chId");
                    param.Add("chId", chId.Value);
                }

                if (payeeId.HasValue)
                {
                    sql.Append(" and payeeid = @payeeId");
                    param.Add("payeeId", payeeId.Value);
                }

                sql.Append(" order by id");

                var rows = await conn.QueryAsync<TdsEntryDto>(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(rows);
            });
        }).WithName("ListTdsEntries");

        // GET /api/tdsentries/{id}
        grp.MapGet("/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql =
                    @"select id, payeeid, chid, subcode, ayid,
                             payeename, payername, section, nature, descrp,
                             datepayment, datededuct, typededuct,
                             amtpay, tdsrate, surcharge, tdsdeduct, surdeduct, cess,
                             datedeposit, totaltds2, tdsdedlater,
                             formtype, tdsapp, ack15ca, certno,
                             dtvalf, dtvalt, dtpaying, dtcomm,
                             evalid, actualtds, actualrate,
                             chinterest, chtdsdep, deductioncode, pcode
                      from tdsentry
                      where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync<TdsEntryDto>(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            });
        }).WithName("GetTdsEntry");

        // POST /api/tdsentries
        grp.MapPost("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, TdsEntryDto dto) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql =
                    @"insert into tdsentry
                        (payeeid, chid, subcode, ayid,
                         payeename, payername, section, nature, descrp,
                         datepayment, datededuct, typededuct,
                         amtpay, tdsrate, surcharge, tdsdeduct, surdeduct, cess,
                         datedeposit, totaltds2, tdsdedlater,
                         formtype, tdsapp, ack15ca, certno,
                         dtvalf, dtvalt, dtpaying, dtcomm,
                         evalid, actualtds, actualrate,
                         chinterest, chtdsdep, deductioncode, pcode)
                      values
                        (@payeeId, @chId, @subCode, @ayId,
                         @payeeName, @payerName, @section, @nature, @descrp,
                         @datePayment, @dateDeduct, @typeDeduct,
                         @amtPay, @tdsRate, @surcharge, @tdsDeduct, @surDeduct, @cess,
                         @dateDeposit, @totalTds2, @tdsDedLater,
                         @formType, @tdsApp, @ack15Ca, @certNo,
                         @dtValF, @dtValT, @dtPaying, @dtComm,
                         @eValid, @actualTds, @actualRate,
                         @chInterest, @chTdsDep, @deductionCode, @pCode)
                      returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, new
                    {
                        payeeId      = dto.PayeeId,
                        chId         = dto.ChId,
                        subCode      = dto.SubCode,
                        ayId         = dto.AyId,
                        payeeName    = dto.PayeeName,
                        payerName    = dto.PayerName,
                        section      = dto.Section,
                        nature       = dto.Nature,
                        descrp       = dto.Descrp,
                        datePayment  = dto.DatePayment,
                        dateDeduct   = dto.DateDeduct,
                        typeDeduct   = dto.TypeDeduct,
                        amtPay       = dto.AmtPay,
                        tdsRate      = dto.TdsRate,
                        surcharge    = dto.Surcharge,
                        tdsDeduct    = dto.TdsDeduct,
                        surDeduct    = dto.SurDeduct,
                        cess         = dto.Cess,
                        dateDeposit  = dto.DateDeposit,
                        totalTds2    = dto.TotalTds2,
                        tdsDedLater  = dto.TdsDedLater,
                        formType     = dto.FormType,
                        tdsApp       = dto.TdsApp,
                        ack15Ca      = dto.Ack15Ca,
                        certNo       = dto.CertNo,
                        dtValF       = dto.DtValF,
                        dtValT       = dto.DtValT,
                        dtPaying     = dto.DtPaying,
                        dtComm       = dto.DtComm,
                        eValid       = dto.EValid,
                        actualTds    = dto.ActualTds,
                        actualRate   = dto.ActualRate,
                        chInterest   = dto.ChInterest,
                        chTdsDep     = dto.ChTdsDep,
                        deductionCode = dto.DeductionCode,
                        pCode        = dto.PCode
                    }, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            });
        }).WithName("CreateTdsEntry");

        // PUT /api/tdsentries/{id}
        grp.MapPut("/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id, TdsEntryDto dto) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql =
                    @"update tdsentry set
                         payeeid       = @payeeId,
                         chid          = @chId,
                         subcode       = @subCode,
                         ayid          = @ayId,
                         payeename     = @payeeName,
                         payername     = @payerName,
                         section       = @section,
                         nature        = @nature,
                         descrp        = @descrp,
                         datepayment   = @datePayment,
                         datededuct    = @dateDeduct,
                         typededuct    = @typeDeduct,
                         amtpay        = @amtPay,
                         tdsrate       = @tdsRate,
                         surcharge     = @surcharge,
                         tdsdeduct     = @tdsDeduct,
                         surdeduct     = @surDeduct,
                         cess          = @cess,
                         datedeposit   = @dateDeposit,
                         totaltds2     = @totalTds2,
                         tdsdedlater   = @tdsDedLater,
                         formtype      = @formType,
                         tdsapp        = @tdsApp,
                         ack15ca       = @ack15Ca,
                         certno        = @certNo,
                         dtvalf        = @dtValF,
                         dtvalt        = @dtValT,
                         dtpaying      = @dtPaying,
                         dtcomm        = @dtComm,
                         evalid        = @eValid,
                         actualtds     = @actualTds,
                         actualrate    = @actualRate,
                         chinterest    = @chInterest,
                         chtdsdep      = @chTdsDep,
                         deductioncode = @deductionCode,
                         pcode         = @pCode
                      where id = @id";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new
                    {
                        id,
                        payeeId      = dto.PayeeId,
                        chId         = dto.ChId,
                        subCode      = dto.SubCode,
                        ayId         = dto.AyId,
                        payeeName    = dto.PayeeName,
                        payerName    = dto.PayerName,
                        section      = dto.Section,
                        nature       = dto.Nature,
                        descrp       = dto.Descrp,
                        datePayment  = dto.DatePayment,
                        dateDeduct   = dto.DateDeduct,
                        typeDeduct   = dto.TypeDeduct,
                        amtPay       = dto.AmtPay,
                        tdsRate      = dto.TdsRate,
                        surcharge    = dto.Surcharge,
                        tdsDeduct    = dto.TdsDeduct,
                        surDeduct    = dto.SurDeduct,
                        cess         = dto.Cess,
                        dateDeposit  = dto.DateDeposit,
                        totalTds2    = dto.TotalTds2,
                        tdsDedLater  = dto.TdsDedLater,
                        formType     = dto.FormType,
                        tdsApp       = dto.TdsApp,
                        ack15Ca      = dto.Ack15Ca,
                        certNo       = dto.CertNo,
                        dtValF       = dto.DtValF,
                        dtValT       = dto.DtValT,
                        dtPaying     = dto.DtPaying,
                        dtComm       = dto.DtComm,
                        eValid       = dto.EValid,
                        actualTds    = dto.ActualTds,
                        actualRate   = dto.ActualRate,
                        chInterest   = dto.ChInterest,
                        chTdsDep     = dto.ChTdsDep,
                        deductionCode = dto.DeductionCode,
                        pCode        = dto.PCode
                    }, cancellationToken: ct));
                return affected == 0 ? Results.NotFound() : Results.NoContent();
            });
        }).WithName("UpdateTdsEntry");

        // DELETE /api/tdsentries/{id}  — hard delete (no isdeleted column on tdsentry)
        grp.MapDelete("/{id:int}", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct, int id) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "delete from tdsentry where id = @id";
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return affected == 0 ? Results.NotFound() : Results.NoContent();
            });
        }).WithName("DeleteTdsEntry");
    }
}
