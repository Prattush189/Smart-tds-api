using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Per-assessment-year CRUD for the year-DB table <c>tdscompincome</c>
/// consumed by SmartTdsBAL.TdsCompIncomeBal. The X-Assessment-Year header
/// selects the database (same pattern as YearDataEndpoints / SalaryEndpoints).
/// pk = id; soft delete via the isdeleted column.
/// </summary>
public static class CompIncomeEndpoints
{
    private const string Cols = @"id, subcode, ayid, pcode, salary_id,
        salaryold, salarynew, businessold, businessnew, propertyold, propertynew,
        stcgold, stcgnew, cg20old, cg20new, cg125old, cg125new,
        othersrcold, othersrcnew, nscintold, nscintnew, proplossold, proplossnew,
        lotteryold, lotterynew, agriold, agrinew,
        gtiold, gtinew, ded80cold, ded80cnew, dedviaold, dedvianew,
        totalincomeold, totalincomenew,
        taxcg20old, taxcg20new, taxcg125old, taxcg125new,
        taxotherincold, taxotherincnew, taxlotteryold, taxlotterynew,
        totaltaxold, totaltaxnew, rebate87aold, rebate87anew,
        surchargeold, surchargenew, cessold, cessnew,
        taxpayableold, taxpayablenew, reliefold, reliefnew, nettaxold, nettaxnew,
        adoptedmethod, adoptedtax,
        prevempsalary, prevemptds, prevempbasic,
        tds192_2b, tax192_1a, modifiedon, isdeleted";

    public static void MapCompIncomeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tdscompincome").RequireAuthorization();

        // -----------------------------------------------------------------
        // GET /api/tdscompincome?subCode=&ayId=&pcode=
        // pcode is optional; when omitted (-1) all payees for the AY are returned.
        // -----------------------------------------------------------------
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId, int pcode = -1) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {Cols} from tdscompincome
                            where subcode = @subCode and ayid = @ayId
                              and (@pcode = -1 or pcode = @pcode)
                              and (isdeleted is null or isdeleted = false)
                            order by id desc";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId, pcode }, cancellationToken: ct));
                return Results.Ok(rows);
            });
        }).WithName("ListTdsCompIncome");

        // GET /api/tdscompincome/{id}
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {Cols} from tdscompincome where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            });
        }).WithName("GetTdsCompIncome");

        // POST /api/tdscompincome  -> RETURNING id
        grp.MapPost("/", async (TdsCompIncomeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into tdscompincome (
                        subcode, ayid, pcode, salary_id,
                        salaryold, salarynew, businessold, businessnew, propertyold, propertynew,
                        stcgold, stcgnew, cg20old, cg20new, cg125old, cg125new,
                        othersrcold, othersrcnew, nscintold, nscintnew, proplossold, proplossnew,
                        lotteryold, lotterynew, agriold, agrinew,
                        gtiold, gtinew, ded80cold, ded80cnew, dedviaold, dedvianew,
                        totalincomeold, totalincomenew,
                        taxcg20old, taxcg20new, taxcg125old, taxcg125new,
                        taxotherincold, taxotherincnew, taxlotteryold, taxlotterynew,
                        totaltaxold, totaltaxnew, rebate87aold, rebate87anew,
                        surchargeold, surchargenew, cessold, cessnew,
                        taxpayableold, taxpayablenew, reliefold, reliefnew, nettaxold, nettaxnew,
                        adoptedmethod, adoptedtax,
                        prevempsalary, prevemptds, prevempbasic,
                        tds192_2b, tax192_1a, modifiedon, isdeleted)
                    values (
                        @SubCode, @AyId, @Pcode, @Salary_id,
                        @SalaryOld, @SalaryNew, @BusinessOld, @BusinessNew, @PropertyOld, @PropertyNew,
                        @StcgOld, @StcgNew, @Cg20Old, @Cg20New, @Cg125Old, @Cg125New,
                        @OtherSrcOld, @OtherSrcNew, @NscIntOld, @NscIntNew, @PropLossOld, @PropLossNew,
                        @LotteryOld, @LotteryNew, @AgriOld, @AgriNew,
                        @GtiOld, @GtiNew, @Ded80COld, @Ded80CNew, @DedVIAOld, @DedVIANew,
                        @TotalIncomeOld, @TotalIncomeNew,
                        @TaxCG20Old, @TaxCG20New, @TaxCG125Old, @TaxCG125New,
                        @TaxOtherIncOld, @TaxOtherIncNew, @TaxLotteryOld, @TaxLotteryNew,
                        @TotalTaxOld, @TotalTaxNew, @Rebate87AOld, @Rebate87ANew,
                        @SurchargeOld, @SurchargeNew, @CessOld, @CessNew,
                        @TaxPayableOld, @TaxPayableNew, @ReliefOld, @ReliefNew, @NetTaxOld, @NetTaxNew,
                        @AdoptedMethod, @AdoptedTax,
                        @PrevEmpSalary, @PrevEmpTds, @PrevEmpBasic,
                        @Tds192_2B, @Tax192_1A, now(), false)
                    returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            });
        }).WithName("CreateTdsCompIncome");

        // PUT /api/tdscompincome/{id}
        grp.MapPut("/{id:int}", async (int id, TdsCompIncomeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update tdscompincome set
                        subcode = @SubCode, ayid = @AyId, pcode = @Pcode, salary_id = @Salary_id,
                        salaryold = @SalaryOld, salarynew = @SalaryNew,
                        businessold = @BusinessOld, businessnew = @BusinessNew,
                        propertyold = @PropertyOld, propertynew = @PropertyNew,
                        stcgold = @StcgOld, stcgnew = @StcgNew,
                        cg20old = @Cg20Old, cg20new = @Cg20New,
                        cg125old = @Cg125Old, cg125new = @Cg125New,
                        othersrcold = @OtherSrcOld, othersrcnew = @OtherSrcNew,
                        nscintold = @NscIntOld, nscintnew = @NscIntNew,
                        proplossold = @PropLossOld, proplossnew = @PropLossNew,
                        lotteryold = @LotteryOld, lotterynew = @LotteryNew,
                        agriold = @AgriOld, agrinew = @AgriNew,
                        gtiold = @GtiOld, gtinew = @GtiNew,
                        ded80cold = @Ded80COld, ded80cnew = @Ded80CNew,
                        dedviaold = @DedVIAOld, dedvianew = @DedVIANew,
                        totalincomeold = @TotalIncomeOld, totalincomenew = @TotalIncomeNew,
                        taxcg20old = @TaxCG20Old, taxcg20new = @TaxCG20New,
                        taxcg125old = @TaxCG125Old, taxcg125new = @TaxCG125New,
                        taxotherincold = @TaxOtherIncOld, taxotherincnew = @TaxOtherIncNew,
                        taxlotteryold = @TaxLotteryOld, taxlotterynew = @TaxLotteryNew,
                        totaltaxold = @TotalTaxOld, totaltaxnew = @TotalTaxNew,
                        rebate87aold = @Rebate87AOld, rebate87anew = @Rebate87ANew,
                        surchargeold = @SurchargeOld, surchargenew = @SurchargeNew,
                        cessold = @CessOld, cessnew = @CessNew,
                        taxpayableold = @TaxPayableOld, taxpayablenew = @TaxPayableNew,
                        reliefold = @ReliefOld, reliefnew = @ReliefNew,
                        nettaxold = @NetTaxOld, nettaxnew = @NetTaxNew,
                        adoptedmethod = @AdoptedMethod, adoptedtax = @AdoptedTax,
                        prevempsalary = @PrevEmpSalary, prevemptds = @PrevEmpTds, prevempbasic = @PrevEmpBasic,
                        tds192_2b = @Tds192_2B, tax192_1a = @Tax192_1A, modifiedon = now()
                    where id = @id";
                var affected = await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    id,
                    body.SubCode, body.AyId, body.Pcode, body.Salary_id,
                    body.SalaryOld, body.SalaryNew, body.BusinessOld, body.BusinessNew,
                    body.PropertyOld, body.PropertyNew, body.StcgOld, body.StcgNew,
                    body.Cg20Old, body.Cg20New, body.Cg125Old, body.Cg125New,
                    body.OtherSrcOld, body.OtherSrcNew, body.NscIntOld, body.NscIntNew,
                    body.PropLossOld, body.PropLossNew, body.LotteryOld, body.LotteryNew,
                    body.AgriOld, body.AgriNew, body.GtiOld, body.GtiNew,
                    body.Ded80COld, body.Ded80CNew, body.DedVIAOld, body.DedVIANew,
                    body.TotalIncomeOld, body.TotalIncomeNew,
                    body.TaxCG20Old, body.TaxCG20New, body.TaxCG125Old, body.TaxCG125New,
                    body.TaxOtherIncOld, body.TaxOtherIncNew, body.TaxLotteryOld, body.TaxLotteryNew,
                    body.TotalTaxOld, body.TotalTaxNew, body.Rebate87AOld, body.Rebate87ANew,
                    body.SurchargeOld, body.SurchargeNew, body.CessOld, body.CessNew,
                    body.TaxPayableOld, body.TaxPayableNew, body.ReliefOld, body.ReliefNew,
                    body.NetTaxOld, body.NetTaxNew, body.AdoptedMethod, body.AdoptedTax,
                    body.PrevEmpSalary, body.PrevEmpTds, body.PrevEmpBasic,
                    body.Tds192_2B, body.Tax192_1A
                }, cancellationToken: ct));
                if (affected == 0) return Results.NotFound(new { error = $"TdsCompIncome id {id} not found." });
                return Results.NoContent();
            });
        }).WithName("UpdateTdsCompIncome");

        // DELETE /api/tdscompincome/{id}  — soft delete via isdeleted
        grp.MapDelete("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var err)) return err;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "update tdscompincome set isdeleted = true, modifiedon = now() where id = @id";
                await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return Results.NoContent();
            });
        }).WithName("DeleteTdsCompIncome");
    }
}

// =====================================================================
// Request DTO (write body). Property names match SmartTdsEntities.TdsCompIncome
// so the BAL can POST/PUT its entity directly.
// =====================================================================
public sealed record TdsCompIncomeDto
{
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public int Pcode { get; init; }
    public int Salary_id { get; init; }

    public double SalaryOld { get; init; }
    public double SalaryNew { get; init; }
    public double BusinessOld { get; init; }
    public double BusinessNew { get; init; }
    public double PropertyOld { get; init; }
    public double PropertyNew { get; init; }
    public double StcgOld { get; init; }
    public double StcgNew { get; init; }
    public double Cg20Old { get; init; }
    public double Cg20New { get; init; }
    public double Cg125Old { get; init; }
    public double Cg125New { get; init; }
    public double OtherSrcOld { get; init; }
    public double OtherSrcNew { get; init; }
    public double NscIntOld { get; init; }
    public double NscIntNew { get; init; }
    public double PropLossOld { get; init; }
    public double PropLossNew { get; init; }
    public double LotteryOld { get; init; }
    public double LotteryNew { get; init; }
    public double AgriOld { get; init; }
    public double AgriNew { get; init; }

    public double GtiOld { get; init; }
    public double GtiNew { get; init; }
    public double Ded80COld { get; init; }
    public double Ded80CNew { get; init; }
    public double DedVIAOld { get; init; }
    public double DedVIANew { get; init; }
    public double TotalIncomeOld { get; init; }
    public double TotalIncomeNew { get; init; }

    public double TaxCG20Old { get; init; }
    public double TaxCG20New { get; init; }
    public double TaxCG125Old { get; init; }
    public double TaxCG125New { get; init; }
    public double TaxOtherIncOld { get; init; }
    public double TaxOtherIncNew { get; init; }
    public double TaxLotteryOld { get; init; }
    public double TaxLotteryNew { get; init; }
    public double TotalTaxOld { get; init; }
    public double TotalTaxNew { get; init; }
    public double Rebate87AOld { get; init; }
    public double Rebate87ANew { get; init; }
    public double SurchargeOld { get; init; }
    public double SurchargeNew { get; init; }
    public double CessOld { get; init; }
    public double CessNew { get; init; }
    public double TaxPayableOld { get; init; }
    public double TaxPayableNew { get; init; }
    public double ReliefOld { get; init; }
    public double ReliefNew { get; init; }
    public double NetTaxOld { get; init; }
    public double NetTaxNew { get; init; }

    public string? AdoptedMethod { get; init; }
    public double AdoptedTax { get; init; }

    public double PrevEmpSalary { get; init; }
    public double PrevEmpTds { get; init; }
    public double PrevEmpBasic { get; init; }

    public double Tds192_2B { get; init; }
    public double Tax192_1A { get; init; }
}
