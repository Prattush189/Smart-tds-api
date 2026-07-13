using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

/// <summary>Projection of smarttds&lt;year&gt;.salary (per-year routed data).</summary>
public sealed record SalaryDto
{
    public int Id { get; init; }
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public string? SalType { get; init; }
    public string? NameOfEmployer { get; init; }
    public string? NatureOfEmployment { get; init; }
    public string? PanOfEmployer { get; init; }
    public string? TanOfEmployer { get; init; }
    public int? CountryCode { get; init; }
    public string? AddrDetail { get; init; }
    public string? CityOrTownOrDistrict { get; init; }
    public string? StateCode { get; init; }
    public int? PinCode { get; init; }
    public string? ZipCode { get; init; }
    public decimal GrossSalary { get; init; }
    public decimal ValueOfPerquisites { get; init; }
    public decimal ProfitsInLieuOfSalary { get; init; }
    public decimal IncomeNotified89a { get; init; }
    public decimal IncomeNotifiedOther89a { get; init; }
    public decimal IncomeNotifiedPrYr89a { get; init; }
    public decimal? AllwncExemptUs10 { get; init; }
    public decimal? IncReliefUs89a { get; init; }
    public decimal? DeductionUnderSection16ia { get; init; }
    public decimal? EntertainmntAlwncUs16ii { get; init; }
    public decimal? ProfessionalTaxUs16iii { get; init; }
    public decimal? Hra { get; init; }
    public decimal? ActualRent { get; init; }
    public bool WhetherMetro { get; init; }
    public decimal? ExemptHra { get; init; }
    public decimal? HraSalary { get; init; }
    public decimal? Arrears { get; init; }
    public decimal? TaxableSalary { get; init; }
    public decimal? TaxableSalaryNew { get; init; }
    public bool DeductionUnderSection16iaFlag { get; init; }
    public decimal? DeductionUnderSection16iaNew { get; init; }
    public decimal? DearnessAllwnc { get; init; }
    public int? PCode { get; init; }
}

/// <summary>Projection of salaryexemptallowances.</summary>
public sealed record SalaryExemptAllowanceDto
{
    public int Id { get; init; }
    public int SalId { get; init; }
    public string? SalNatureDesc { get; init; }
    public string? SalOthNatOfInc { get; init; }
    public decimal SalOthAmount { get; init; }
}

/// <summary>Projection of salarynaturedetails.</summary>
public sealed record SalaryNatureDetailDto
{
    public int Id { get; init; }
    public int SalId { get; init; }
    public string? NatureDesc { get; init; }
    public string? OthNatOfInc { get; init; }
    public decimal OthAmount { get; init; }
}

/// <summary>Projection of salaryperquisitedetails.</summary>
public sealed record SalaryPerquisiteDetailDto
{
    public int Id { get; init; }
    public int SalId { get; init; }
    public string? NatureDesc { get; init; }
    public string? OthNatOfInc { get; init; }
    public decimal OthAmount { get; init; }
}

/// <summary>Composite GET-by-id response: salary parent + all three child lists.</summary>
public sealed record SalaryWithDetailsDto(
    SalaryDto Salary,
    IEnumerable<SalaryExemptAllowanceDto> ExemptAllowances,
    IEnumerable<SalaryNatureDetailDto> NatureDetails,
    IEnumerable<SalaryPerquisiteDetailDto> PerquisiteDetails);

/// <summary>POST / PUT request body.</summary>
public sealed record SalaryRequest(
    SalaryDto Salary,
    List<SalaryExemptAllowanceDto>? ExemptAllowances,
    List<SalaryNatureDetailDto>? NatureDetails,
    List<SalaryPerquisiteDetailDto>? PerquisiteDetails);

// ---------------------------------------------------------------------------
// Endpoints
// ---------------------------------------------------------------------------

public static class SalaryEndpoints
{
    public static void MapSalaryEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/salaries").RequireAuthorization();

        // ------------------------------------------------------------------
        // GET /api/salaries?subCode=&ayId=
        // List salary rows filtered by subcode + ayid (matches SalaryBal.GetAll).
        // ------------------------------------------------------------------
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    select id, subcode, ayid, saltype, nameofemployer, natureofemployment,
                           panofemployer, tanofemployer, countrycode, addrdetail,
                           cityortownordistrict, statecode, pincode, zipcode,
                           grosssalary, valueofperquisites, profitsinlieuofsalary,
                           incomenotified89a, incomenotifiedother89a, incomenotifiedpryr89a,
                           allwncexemptus10, increliefus89a, deductionundersection16ia,
                           entertainmntalwncus16ii, professionaltaxus16iii,
                           hra, actualrent, whethermetro, exempthra, hrasalary, arrears,
                           taxablesalary, taxablesalarynew,
                           deductionundersection16iaflag, deductionundersection16ianew,
                           dearnessallwnc, pcode
                    from salary
                    where subcode = @subCode and ayid = @ayId
                    order by id";
                var rows = await conn.QueryAsync<SalaryDto>(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            });
        }).WithName("ListSalaries");

        // ------------------------------------------------------------------
        // GET /api/salaries/{id}
        // Salary parent + all 3 child detail lists.
        // ------------------------------------------------------------------
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);

                const string sqlSalary = @"
                    select id, subcode, ayid, saltype, nameofemployer, natureofemployment,
                           panofemployer, tanofemployer, countrycode, addrdetail,
                           cityortownordistrict, statecode, pincode, zipcode,
                           grosssalary, valueofperquisites, profitsinlieuofsalary,
                           incomenotified89a, incomenotifiedother89a, incomenotifiedpryr89a,
                           allwncexemptus10, increliefus89a, deductionundersection16ia,
                           entertainmntalwncus16ii, professionaltaxus16iii,
                           hra, actualrent, whethermetro, exempthra, hrasalary, arrears,
                           taxablesalary, taxablesalarynew,
                           deductionundersection16iaflag, deductionundersection16ianew,
                           dearnessallwnc, pcode
                    from salary
                    where id = @id";

                var salary = await conn.QuerySingleOrDefaultAsync<SalaryDto>(
                    new CommandDefinition(sqlSalary, new { id }, cancellationToken: ct));

                if (salary is null)
                    return Results.NotFound(new { error = $"Salary id {id} not found." });

                const string sqlExempt = @"
                    select id, salid, salnaturedesc, salothnatofinc, salothamount
                    from salaryexemptallowances
                    where salid = @id";
                const string sqlNature = @"
                    select id, salid, naturedesc, othnatofinc, othamount
                    from salarynaturedetails
                    where salid = @id";
                const string sqlPerq = @"
                    select id, salid, naturedesc, othnatofinc, othamount
                    from salaryperquisitedetails
                    where salid = @id";

                var param = new { id };
                var exempt = await conn.QueryAsync<SalaryExemptAllowanceDto>(
                    new CommandDefinition(sqlExempt, param, cancellationToken: ct));
                var nature = await conn.QueryAsync<SalaryNatureDetailDto>(
                    new CommandDefinition(sqlNature, param, cancellationToken: ct));
                var perq = await conn.QueryAsync<SalaryPerquisiteDetailDto>(
                    new CommandDefinition(sqlPerq, param, cancellationToken: ct));

                return Results.Ok(new SalaryWithDetailsDto(salary, exempt, nature, perq));
            });
        }).WithName("GetSalary");

        // ------------------------------------------------------------------
        // POST /api/salaries
        // Insert salary RETURNING id, then insert provided child rows.
        // ------------------------------------------------------------------
        grp.MapPost("/", async (SalaryRequest body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var s = body.Salary;
                if (s is null)
                    return Results.BadRequest(new { error = "Request body must include a 'salary' object." });

                const string sqlInsert = @"
                    insert into salary (
                        subcode, ayid, saltype, nameofemployer, natureofemployment,
                        panofemployer, tanofemployer, countrycode, addrdetail,
                        cityortownordistrict, statecode, pincode, zipcode,
                        grosssalary, valueofperquisites, profitsinlieuofsalary,
                        incomenotified89a, incomenotifiedother89a, incomenotifiedpryr89a,
                        allwncexemptus10, increliefus89a, deductionundersection16ia,
                        entertainmntalwncus16ii, professionaltaxus16iii,
                        hra, actualrent, whethermetro, exempthra, hrasalary, arrears,
                        taxablesalary, taxablesalarynew,
                        deductionundersection16iaflag, deductionundersection16ianew,
                        dearnessallwnc, pcode
                    ) values (
                        @SubCode, @AyId, @SalType, @NameOfEmployer, @NatureOfEmployment,
                        @PanOfEmployer, @TanOfEmployer, @CountryCode, @AddrDetail,
                        @CityOrTownOrDistrict, @StateCode, @PinCode, @ZipCode,
                        @GrossSalary, @ValueOfPerquisites, @ProfitsInLieuOfSalary,
                        @IncomeNotified89a, @IncomeNotifiedOther89a, @IncomeNotifiedPrYr89a,
                        @AllwncExemptUs10, @IncReliefUs89a, @DeductionUnderSection16ia,
                        @EntertainmntAlwncUs16ii, @ProfessionalTaxUs16iii,
                        @Hra, @ActualRent, @WhetherMetro, @ExemptHra, @HraSalary, @Arrears,
                        @TaxableSalary, @TaxableSalaryNew,
                        @DeductionUnderSection16iaFlag, @DeductionUnderSection16iaNew,
                        @DearnessAllwnc, @PCode
                    ) returning id";

                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sqlInsert, s, cancellationToken: ct));

                await InsertChildRows(conn, newId, body, ct);

                return Results.Ok(new { id = newId });
            });
        }).WithName("CreateSalary");

        // ------------------------------------------------------------------
        // PUT /api/salaries/{id}
        // Update salary parent; delete + re-insert all child rows.
        // ------------------------------------------------------------------
        grp.MapPut("/{id:int}", async (int id, SalaryRequest body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var s = body.Salary;

                const string sqlUpdate = @"
                    update salary set
                        subcode = @SubCode, ayid = @AyId, saltype = @SalType,
                        nameofemployer = @NameOfEmployer, natureofemployment = @NatureOfEmployment,
                        panofemployer = @PanOfEmployer, tanofemployer = @TanOfEmployer,
                        countrycode = @CountryCode, addrdetail = @AddrDetail,
                        cityortownordistrict = @CityOrTownOrDistrict, statecode = @StateCode,
                        pincode = @PinCode, zipcode = @ZipCode,
                        grosssalary = @GrossSalary, valueofperquisites = @ValueOfPerquisites,
                        profitsinlieuofsalary = @ProfitsInLieuOfSalary,
                        incomenotified89a = @IncomeNotified89a,
                        incomenotifiedother89a = @IncomeNotifiedOther89a,
                        incomenotifiedpryr89a = @IncomeNotifiedPrYr89a,
                        allwncexemptus10 = @AllwncExemptUs10, increliefus89a = @IncReliefUs89a,
                        deductionundersection16ia = @DeductionUnderSection16ia,
                        entertainmntalwncus16ii = @EntertainmntAlwncUs16ii,
                        professionaltaxus16iii = @ProfessionalTaxUs16iii,
                        hra = @Hra, actualrent = @ActualRent, whethermetro = @WhetherMetro,
                        exempthra = @ExemptHra, hrasalary = @HraSalary, arrears = @Arrears,
                        taxablesalary = @TaxableSalary, taxablesalarynew = @TaxableSalaryNew,
                        deductionundersection16iaflag = @DeductionUnderSection16iaFlag,
                        deductionundersection16ianew = @DeductionUnderSection16iaNew,
                        dearnessallwnc = @DearnessAllwnc, pcode = @PCode
                    where id = @id";

                var affected = await conn.ExecuteAsync(
                    new CommandDefinition(sqlUpdate, new { s.SubCode, s.AyId, s.SalType,
                        s.NameOfEmployer, s.NatureOfEmployment, s.PanOfEmployer, s.TanOfEmployer,
                        s.CountryCode, s.AddrDetail, s.CityOrTownOrDistrict, s.StateCode,
                        s.PinCode, s.ZipCode, s.GrossSalary, s.ValueOfPerquisites,
                        s.ProfitsInLieuOfSalary, s.IncomeNotified89a, s.IncomeNotifiedOther89a,
                        s.IncomeNotifiedPrYr89a, s.AllwncExemptUs10, s.IncReliefUs89a,
                        s.DeductionUnderSection16ia, s.EntertainmntAlwncUs16ii,
                        s.ProfessionalTaxUs16iii, s.Hra, s.ActualRent, s.WhetherMetro,
                        s.ExemptHra, s.HraSalary, s.Arrears, s.TaxableSalary, s.TaxableSalaryNew,
                        s.DeductionUnderSection16iaFlag, s.DeductionUnderSection16iaNew,
                        s.DearnessAllwnc, s.PCode, id }, cancellationToken: ct));

                if (affected == 0)
                    return Results.NotFound(new { error = $"Salary id {id} not found." });

                // Delete all child rows for this salary then re-insert the provided ones.
                await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salaryexemptallowances where salid = @id",
                    new { id }, cancellationToken: ct));
                await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salarynaturedetails where salid = @id",
                    new { id }, cancellationToken: ct));
                await conn.ExecuteAsync(new CommandDefinition(
                    "delete from salaryperquisitedetails where salid = @id",
                    new { id }, cancellationToken: ct));

                await InsertChildRows(conn, id, body, ct);

                return Results.NoContent();
            });
        }).WithName("UpdateSalary");

        // ------------------------------------------------------------------
        // DELETE /api/salaries/{id}
        // Hard-delete salary; children cascade via FK ON DELETE CASCADE.
        // ------------------------------------------------------------------
        grp.MapDelete("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var affected = await conn.ExecuteAsync(
                    new CommandDefinition("delete from salary where id = @id",
                        new { id }, cancellationToken: ct));

                if (affected == 0)
                    return Results.NotFound(new { error = $"Salary id {id} not found." });

                return Results.NoContent();
            });
        }).WithName("DeleteSalary");
    }

    // -----------------------------------------------------------------------
    // Private helper: insert child rows for a given salId.
    // -----------------------------------------------------------------------
    private static async Task InsertChildRows(
        System.Data.IDbConnection conn, int salId, SalaryRequest body, CancellationToken ct)
    {
        if (body.ExemptAllowances is { Count: > 0 })
        {
            const string sql = @"
                insert into salaryexemptallowances (salid, salnaturedesc, salothnatofinc, salothamount)
                values (@SalId, @SalNatureDesc, @SalOthNatOfInc, @SalOthAmount)";
            foreach (var row in body.ExemptAllowances)
                await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { SalId = salId, row.SalNatureDesc, row.SalOthNatOfInc, row.SalOthAmount },
                    cancellationToken: ct));
        }

        if (body.NatureDetails is { Count: > 0 })
        {
            const string sql = @"
                insert into salarynaturedetails (salid, naturedesc, othnatofinc, othamount)
                values (@SalId, @NatureDesc, @OthNatOfInc, @OthAmount)";
            foreach (var row in body.NatureDetails)
                await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { SalId = salId, row.NatureDesc, row.OthNatOfInc, row.OthAmount },
                    cancellationToken: ct));
        }

        if (body.PerquisiteDetails is { Count: > 0 })
        {
            const string sql = @"
                insert into salaryperquisitedetails (salid, naturedesc, othnatofinc, othamount)
                values (@SalId, @NatureDesc, @OthNatOfInc, @OthAmount)";
            foreach (var row in body.PerquisiteDetails)
                await conn.ExecuteAsync(new CommandDefinition(sql,
                    new { SalId = salId, row.NatureDesc, row.OthNatOfInc, row.OthAmount },
                    cancellationToken: ct));
        }
    }
}
