using Dapper;
using Npgsql;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>Projection of smarttds&lt;year&gt;.payee (per-year routed data).</summary>
public sealed record PayeeDto
{
    public int Id { get; init; }
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public int? TsId { get; init; }
    public string? EmpFlag { get; init; }
    public string? Pan { get; init; }
    public string? PanStatus { get; init; }
    public string? Name { get; init; }
    public string? Add1 { get; init; }
    public string? Add2 { get; init; }
    public string? Add3 { get; init; }
    public string? Add4 { get; init; }
    public string? City { get; init; }
    public string? DoB { get; init; }
    public string? DoJ { get; init; }
    public string? FName { get; init; }
    public string? Phone { get; init; }
    public string? Phone2 { get; init; }
    public int? Pincode { get; init; }
    public int? Zipcode { get; init; }
    public string? StateName { get; init; }
    public string? Tin { get; init; }
    public string? UserCode { get; init; }
    public string? EmpDesig { get; init; }
    public string? StCode { get; init; }
    public string? DoL { get; init; }
    public string? DoR { get; init; }
    public string? Leaves { get; init; }
    public string? Email { get; init; }
    public string? Email2 { get; init; }
    public string? PanStat { get; init; }
    public string? Flag206ABCCA { get; init; }
    public string? Flag115BAC { get; init; }
    public bool? FreezePan { get; init; }
    public string? Sex { get; init; }
    public string? Status { get; init; }
    public string? RStatus { get; init; }
    public int? Country { get; init; }
    public int? State { get; init; }
    public bool? DirFlag { get; init; }
    public string? TaxRegime { get; init; }
}

public static class PayeeEndpoints
{
    public static void MapPayeeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/payees").RequireAuthorization();

        // GET /api/payees?subCode=&ayId=
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    select id, subcode, ayid, tsid, empflag, pan, panstatus, name,
                           add1, add2, add3, add4, city, dob, doj, fname,
                           phone, phone2, pincode, zipcode, statename, tin,
                           usercode, empdesig, stcode, dol, dor, leaves,
                           email, email2, panstat, flag206abcca, flag115bac,
                           freezepan, sex, status, rstatus, country, state,
                           dirflag, taxregime
                    from payee
                    where subcode = @subCode
                      and ayid = @ayId
                    order by id";
                var rows = await conn.QueryAsync<PayeeDto>(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            });
        }).WithName("ListPayees");

        // GET /api/payees/{id}
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    select id, subcode, ayid, tsid, empflag, pan, panstatus, name,
                           add1, add2, add3, add4, city, dob, doj, fname,
                           phone, phone2, pincode, zipcode, statename, tin,
                           usercode, empdesig, stcode, dol, dor, leaves,
                           email, email2, panstat, flag206abcca, flag115bac,
                           freezepan, sex, status, rstatus, country, state,
                           dirflag, taxregime
                    from payee
                    where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync<PayeeDto>(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            });
        }).WithName("GetPayee");

        // POST /api/payees
        grp.MapPost("/", async (PayeeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into payee
                        (subcode, ayid, tsid, empflag, pan, panstatus, name,
                         add1, add2, add3, add4, city, dob, doj, fname,
                         phone, phone2, pincode, zipcode, statename, tin,
                         usercode, empdesig, stcode, dol, dor, leaves,
                         email, email2, panstat, flag206abcca, flag115bac,
                         freezepan, sex, status, rstatus, country, state,
                         dirflag, taxregime)
                    values
                        (@SubCode, @AyId, @TsId, @EmpFlag, @Pan, @PanStatus, @Name,
                         @Add1, @Add2, @Add3, @Add4, @City, @DoB, @DoJ, @FName,
                         @Phone, @Phone2, @Pincode, @Zipcode, @StateName, @Tin,
                         @UserCode, @EmpDesig, @StCode, @DoL, @DoR, @Leaves,
                         @Email, @Email2, @PanStat, @Flag206ABCCA, @Flag115BAC,
                         @FreezePan, @Sex, @Status, @RStatus, @Country, @State,
                         @DirFlag, @TaxRegime)
                    returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            });
        }).WithName("CreatePayee");

        // PUT /api/payees/{id}
        grp.MapPut("/{id:int}", async (int id, PayeeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update payee set
                        subcode      = @SubCode,
                        ayid         = @AyId,
                        tsid         = @TsId,
                        empflag      = @EmpFlag,
                        pan          = @Pan,
                        panstatus    = @PanStatus,
                        name         = @Name,
                        add1         = @Add1,
                        add2         = @Add2,
                        add3         = @Add3,
                        add4         = @Add4,
                        city         = @City,
                        dob          = @DoB,
                        doj          = @DoJ,
                        fname        = @FName,
                        phone        = @Phone,
                        phone2       = @Phone2,
                        pincode      = @Pincode,
                        zipcode      = @Zipcode,
                        statename    = @StateName,
                        tin          = @Tin,
                        usercode     = @UserCode,
                        empdesig     = @EmpDesig,
                        stcode       = @StCode,
                        dol          = @DoL,
                        dor          = @DoR,
                        leaves       = @Leaves,
                        email        = @Email,
                        email2       = @Email2,
                        panstat      = @PanStat,
                        flag206abcca = @Flag206ABCCA,
                        flag115bac   = @Flag115BAC,
                        freezepan    = @FreezePan,
                        sex          = @Sex,
                        status       = @Status,
                        rstatus      = @RStatus,
                        country      = @Country,
                        state        = @State,
                        dirflag      = @DirFlag,
                        taxregime    = @TaxRegime
                    where id = @id";
                await conn.ExecuteAsync(
                    new CommandDefinition(sql, new
                    {
                        id,
                        body.SubCode, body.AyId, body.TsId, body.EmpFlag, body.Pan, body.PanStatus, body.Name,
                        body.Add1, body.Add2, body.Add3, body.Add4, body.City, body.DoB, body.DoJ, body.FName,
                        body.Phone, body.Phone2, body.Pincode, body.Zipcode, body.StateName, body.Tin,
                        body.UserCode, body.EmpDesig, body.StCode, body.DoL, body.DoR, body.Leaves,
                        body.Email, body.Email2, body.PanStat, body.Flag206ABCCA, body.Flag115BAC,
                        body.FreezePan, body.Sex, body.Status, body.RStatus, body.Country, body.State,
                        body.DirFlag, body.TaxRegime
                    }, cancellationToken: ct));
                return Results.NoContent();
            });
        }).WithName("UpdatePayee");

        // DELETE /api/payees/{id}  — hard delete (payee has no isdeleted column)
        grp.MapDelete("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "delete from payee where id = @id";
                await conn.ExecuteAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return Results.NoContent();
            });
        }).WithName("DeletePayee");

        // POST /api/payees/batch  body [ ...payees ]  → bulk INSERT in one round-trip,
        // returns { ids, count } (ids in declaration order). Used by Excel import so a
        // few-hundred-payee file is one request instead of one PUT/POST per payee.
        grp.MapPost("/batch", async (PayeeDto[] body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            if (body is null || body.Length == 0) return Results.Ok(new { ids = System.Array.Empty<int>(), count = 0 });
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                if (conn is NpgsqlConnection npg && npg.State != System.Data.ConnectionState.Open)
                    await npg.OpenAsync(ct);

                const string sql = @"
                    insert into payee
                        (subcode, ayid, tsid, empflag, pan, panstatus, name,
                         add1, add2, add3, add4, city, dob, doj, fname,
                         phone, phone2, pincode, zipcode, statename, tin,
                         usercode, empdesig, stcode, dol, dor, leaves,
                         email, email2, panstat, flag206abcca, flag115bac,
                         freezepan, sex, status, rstatus, country, state,
                         dirflag, taxregime)
                    values
                        (@SubCode, @AyId, @TsId, @EmpFlag, @Pan, @PanStatus, @Name,
                         @Add1, @Add2, @Add3, @Add4, @City, @DoB, @DoJ, @FName,
                         @Phone, @Phone2, @Pincode, @Zipcode, @StateName, @Tin,
                         @UserCode, @EmpDesig, @StCode, @DoL, @DoR, @Leaves,
                         @Email, @Email2, @PanStat, @Flag206ABCCA, @Flag115BAC,
                         @FreezePan, @Sex, @Status, @RStatus, @Country, @State,
                         @DirFlag, @TaxRegime)
                    returning id";

                using var tx = conn.BeginTransaction();
                var ids = new List<int>(body.Length);
                foreach (var dto in body)
                    ids.Add(await conn.ExecuteScalarAsync<int>(
                        new CommandDefinition(sql, dto, transaction: tx, cancellationToken: ct)));
                tx.Commit();
                return Results.Ok(new { ids, count = ids.Count });
            });
        }).WithName("BatchInsertPayees");

        // POST /api/payees/update-batch  body [ ...payees ]  → bulk UPDATE by id in one
        // round-trip, returns { count }. Used by Excel import to refresh existing payees.
        grp.MapPost("/update-batch", async (PayeeDto[] body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!Api.TryYear(http, out var year, out var bad)) return bad;
            if (body is null || body.Length == 0) return Results.Ok(new { count = 0 });
            return await Api.InYear(year, async () =>
            {
                using var conn = await db.OpenYearAsync(year, ct);
                if (conn is NpgsqlConnection npg && npg.State != System.Data.ConnectionState.Open)
                    await npg.OpenAsync(ct);

                const string sql = @"
                    update payee set
                        subcode=@SubCode, ayid=@AyId, tsid=@TsId, empflag=@EmpFlag, pan=@Pan,
                        panstatus=@PanStatus, name=@Name, add1=@Add1, add2=@Add2, add3=@Add3, add4=@Add4,
                        city=@City, dob=@DoB, doj=@DoJ, fname=@FName, phone=@Phone, phone2=@Phone2,
                        pincode=@Pincode, zipcode=@Zipcode, statename=@StateName, tin=@Tin,
                        usercode=@UserCode, empdesig=@EmpDesig, stcode=@StCode, dol=@DoL, dor=@DoR,
                        leaves=@Leaves, email=@Email, email2=@Email2, panstat=@PanStat,
                        flag206abcca=@Flag206ABCCA, flag115bac=@Flag115BAC, freezepan=@FreezePan,
                        sex=@Sex, status=@Status, rstatus=@RStatus, country=@Country, state=@State,
                        dirflag=@DirFlag, taxregime=@TaxRegime
                    where id = @Id";

                using var tx = conn.BeginTransaction();
                var count = 0;
                foreach (var dto in body)
                    count += await conn.ExecuteAsync(
                        new CommandDefinition(sql, dto, transaction: tx, cancellationToken: ct));
                tx.Commit();
                return Results.Ok(new { count });
            });
        }).WithName("BatchUpdatePayees");
    }
}
