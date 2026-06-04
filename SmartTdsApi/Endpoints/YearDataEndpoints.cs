using Dapper;
using Npgsql;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Per-assessment-year CRUD for the year-DB tables consumed by the
/// SmartTdsBAL layer: tdsdeduction, ddodet, f15hn, f15hnpayee.
/// The X-Assessment-Year header selects the database (same pattern as
/// ChallanEndpoints / PayeeEndpoints). All tables carry an isdeleted
/// column -> DELETE is a soft delete.
/// </summary>
public static class YearDataEndpoints
{
    private const string YearHeader = "X-Assessment-Year";

    private static bool TryYear(HttpRequest http, out string year, out IResult error)
    {
        if (!http.Headers.TryGetValue(YearHeader, out var v) || string.IsNullOrWhiteSpace(v))
        {
            year = null!;
            error = Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });
            return false;
        }
        year = v!;
        error = null!;
        return true;
    }

    public static void MapYearDataEndpoints(this IEndpointRouteBuilder app)
    {
        MapTdsDeductions(app);
        MapDdodet(app);
        MapF15hn(app);
        MapF15hnPayee(app);
    }

    // =====================================================================
    // /api/tdsdeductions   pk = id   (soft delete via isdeleted)
    // =====================================================================
    private static void MapTdsDeductions(IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tdsdeductions").RequireAuthorization();

        const string cols = @"id, subcode, ayid, pcode, ded80id,
                              amount, amount1, amount2, amount3, amount4, amount5, amount6, amount7,
                              dedamt, dedamt2, grossamt, senior, ssenior, severe, date, salary_id,
                              modifiedon, isdeleted";

        // GET /api/tdsdeductions?subCode=&ayId=
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {cols} from tdsdeduction
                            where subcode = @subCode and ayid = @ayId
                              and (isdeleted is null or isdeleted = false)
                            order by id";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("ListTdsDeductions");

        // GET /api/tdsdeductions/{id}
        grp.MapGet("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {cols} from tdsdeduction where id = @id";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("GetTdsDeduction");

        // POST /api/tdsdeductions
        grp.MapPost("/", async (TdsDeductionDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into tdsdeduction
                        (subcode, ayid, pcode, ded80id,
                         amount, amount1, amount2, amount3, amount4, amount5, amount6, amount7,
                         dedamt, dedamt2, grossamt, senior, ssenior, severe, date, salary_id,
                         modifiedon, isdeleted)
                    values
                        (@SubCode, @AyId, @Pcode, @Ded80id,
                         @Amount, @Amount1, @Amount2, @Amount3, @Amount4, @Amount5, @Amount6, @Amount7,
                         @Dedamt, @Dedamt2, @Grossamt, @Senior, @Ssenior, @Severe, @Date, @Salary_id,
                         now(), false)
                    returning id";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("CreateTdsDeduction");

        // PUT /api/tdsdeductions/{id}
        grp.MapPut("/{id:int}", async (int id, TdsDeductionDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update tdsdeduction set
                        subcode  = @SubCode, ayid = @AyId, pcode = @Pcode, ded80id = @Ded80id,
                        amount   = @Amount, amount1 = @Amount1, amount2 = @Amount2, amount3 = @Amount3,
                        amount4  = @Amount4, amount5 = @Amount5, amount6 = @Amount6, amount7 = @Amount7,
                        dedamt   = @Dedamt, dedamt2 = @Dedamt2, grossamt = @Grossamt,
                        senior   = @Senior, ssenior = @Ssenior, severe = @Severe,
                        date     = @Date, salary_id = @Salary_id, modifiedon = now()
                    where id = @id";
                await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    id,
                    body.SubCode, body.AyId, body.Pcode, body.Ded80id,
                    body.Amount, body.Amount1, body.Amount2, body.Amount3, body.Amount4,
                    body.Amount5, body.Amount6, body.Amount7,
                    body.Dedamt, body.Dedamt2, body.Grossamt,
                    body.Senior, body.Ssenior, body.Severe, body.Date, body.Salary_id
                }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("UpdateTdsDeduction");

        // DELETE /api/tdsdeductions/{id}  — soft delete
        grp.MapDelete("/{id:int}", async (int id, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "update tdsdeduction set isdeleted = true where id = @id";
                await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("DeleteTdsDeduction");
    }

    // =====================================================================
    // /api/ddodet   pk = tid   (soft delete via isdeleted)
    // =====================================================================
    private static void MapDdodet(IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/ddodet").RequireAuthorization();

        const string cols = @"tid, subcode, ayid, period, aocode, dcode,
                              tax, tds, nature, mapcode, modifiedon, isdeleted";

        // GET /api/ddodet?subCode=&ayId=
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {cols} from ddodet
                            where subcode = @subCode and ayid = @ayId
                              and (isdeleted is null or isdeleted = false)
                            order by tid";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("ListDdodet");

        // GET /api/ddodet/{tid}
        grp.MapGet("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {cols} from ddodet where tid = @tid";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("GetDdodet");

        // POST /api/ddodet
        grp.MapPost("/", async (DdodetDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into ddodet
                        (subcode, ayid, period, aocode, dcode, tax, tds, nature, mapcode, modifiedon, isdeleted)
                    values
                        (@Subcode, @Ayid, @Period, @Aocode, @Dcode, @Tax, @Tds, @Nature, @Mapcode, now(), false)
                    returning tid";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("CreateDdodet");

        // PUT /api/ddodet/{tid}
        grp.MapPut("/{tid:int}", async (int tid, DdodetDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update ddodet set
                        subcode = @Subcode, ayid = @Ayid, period = @Period, aocode = @Aocode,
                        dcode = @Dcode, tax = @Tax, tds = @Tds, nature = @Nature, mapcode = @Mapcode,
                        modifiedon = now()
                    where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    tid, body.Subcode, body.Ayid, body.Period, body.Aocode, body.Dcode,
                    body.Tax, body.Tds, body.Nature, body.Mapcode
                }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("UpdateDdodet");

        // DELETE /api/ddodet/{tid}  — soft delete
        grp.MapDelete("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "update ddodet set isdeleted = true where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("DeleteDdodet");
    }

    // =====================================================================
    // /api/f15hn   pk = tid   (soft delete; reserved column "desc" quoted)
    // =====================================================================
    private static void MapF15hn(IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/f15hn").RequireAuthorization();

        const string cols = @"tid, subcode, ayid, pcode, amount, ""desc"" as desc,
                              date, nature, section, income, quarter, modifiedon, isdeleted";

        // GET /api/f15hn?subCode=&ayId=
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int subCode, int ayId) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {cols} from f15hn
                            where subcode = @subCode and ayid = @ayId
                              and (isdeleted is null or isdeleted = false)
                            order by tid";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("ListF15hn");

        // GET /api/f15hn/{tid}
        grp.MapGet("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {cols} from f15hn where tid = @tid";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("GetF15hn");

        // POST /api/f15hn
        grp.MapPost("/", async (F15hnDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into f15hn
                        (subcode, ayid, pcode, amount, ""desc"", date, nature, section, income, quarter, modifiedon, isdeleted)
                    values
                        (@Subcode, @Ayid, @Pcode, @Amount, @Desc, @Date, @Nature, @Section, @Income, @Quarter, now(), false)
                    returning tid";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("CreateF15hn");

        // PUT /api/f15hn/{tid}
        grp.MapPut("/{tid:int}", async (int tid, F15hnDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update f15hn set
                        subcode = @Subcode, ayid = @Ayid, pcode = @Pcode, amount = @Amount,
                        ""desc"" = @Desc, date = @Date, nature = @Nature, section = @Section,
                        income = @Income, quarter = @Quarter, modifiedon = now()
                    where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    tid, body.Subcode, body.Ayid, body.Pcode, body.Amount, body.Desc,
                    body.Date, body.Nature, body.Section, body.Income, body.Quarter
                }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("UpdateF15hn");

        // DELETE /api/f15hn/{tid}  — soft delete
        grp.MapDelete("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "update f15hn set isdeleted = true where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("DeleteF15hn");
    }

    // =====================================================================
    // /api/f15hnpayee   pk = tid   (soft delete via isdeleted)
    // =====================================================================
    private static void MapF15hnPayee(IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/f15hnpayee").RequireAuthorization();

        const string cols = @"tid, subcode, ayid, pcode, formid,
                              date15g, date15g2, date15g3, unqno15g, nof15g,
                              value15g, eincome, cincome, amtpaid, layr, type, quarter,
                              modifiedon, isdeleted";

        // GET /api/f15hnpayee?subCode=&ayId=&formId=
        // subCode/ayId/formId are all optional (0/omitted => not filtered) so the
        // BAL's GetAll(subCode, ayId) and GetByFormId(formId) both map here.
        grp.MapGet("/", async (HttpRequest http, IDbConnectionFactory db, CancellationToken ct,
            int? subCode, int? ayId, int? formId) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $@"select {cols} from f15hnpayee
                            where (isdeleted is null or isdeleted = false)
                              and (@subCode is null or @subCode = 0 or subcode = @subCode)
                              and (@ayId    is null or @ayId    = 0 or ayid    = @ayId)
                              and (@formId  is null or @formId  = 0 or formid  = @formId)
                            order by tid";
                var rows = await conn.QueryAsync(
                    new CommandDefinition(sql, new { subCode, ayId, formId }, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("ListF15hnPayee");

        // GET /api/f15hnpayee/{tid}
        grp.MapGet("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                var sql = $"select {cols} from f15hnpayee where tid = @tid";
                var row = await conn.QuerySingleOrDefaultAsync(
                    new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return row is null ? Results.NotFound() : Results.Ok(row);
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("GetF15hnPayee");

        // POST /api/f15hnpayee
        grp.MapPost("/", async (F15hnPayeeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    insert into f15hnpayee
                        (subcode, ayid, pcode, formid, date15g, date15g2, date15g3, unqno15g,
                         nof15g, value15g, eincome, cincome, amtpaid, layr, type, quarter, modifiedon, isdeleted)
                    values
                        (@Subcode, @Ayid, @Pcode, @Formid, @Date15g, @Date15g2, @Date15g3, @Unqno15g,
                         @Nof15g, @Value15g, @Eincome, @Cincome, @AmtPaid, @Layr, @Type, @Quarter, now(), false)
                    returning tid";
                var newId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(sql, body, cancellationToken: ct));
                return Results.Ok(new { id = newId });
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("CreateF15hnPayee");

        // PUT /api/f15hnpayee/{tid}
        grp.MapPut("/{tid:int}", async (int tid, F15hnPayeeDto body, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = @"
                    update f15hnpayee set
                        subcode = @Subcode, ayid = @Ayid, pcode = @Pcode, formid = @Formid,
                        date15g = @Date15g, date15g2 = @Date15g2, date15g3 = @Date15g3, unqno15g = @Unqno15g,
                        nof15g = @Nof15g, value15g = @Value15g, eincome = @Eincome, cincome = @Cincome,
                        amtpaid = @AmtPaid, layr = @Layr, type = @Type, quarter = @Quarter, modifiedon = now()
                    where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new
                {
                    tid, body.Subcode, body.Ayid, body.Pcode, body.Formid,
                    body.Date15g, body.Date15g2, body.Date15g3, body.Unqno15g,
                    body.Nof15g, body.Value15g, body.Eincome, body.Cincome,
                    body.AmtPaid, body.Layr, body.Type, body.Quarter
                }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("UpdateF15hnPayee");

        // DELETE /api/f15hnpayee/{tid}  — soft delete
        grp.MapDelete("/{tid:int}", async (int tid, HttpRequest http, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (!TryYear(http, out var year, out var err)) return err;
            try
            {
                using var conn = await db.OpenYearAsync(year, ct);
                const string sql = "update f15hnpayee set isdeleted = true where tid = @tid";
                await conn.ExecuteAsync(new CommandDefinition(sql, new { tid }, cancellationToken: ct));
                return Results.NoContent();
            }
            catch (ArgumentException ex) { return Results.BadRequest(new { error = ex.Message }); }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            { return Results.NotFound(new { error = $"No data for assessment year '{year}'." }); }
        }).WithName("DeleteF15hnPayee");
    }
}

// =====================================================================
// Request DTOs (write bodies). Names match SmartTdsEntities so the BAL
// can post its entities directly; reads use dynamic Dapper rows.
// =====================================================================

public sealed record TdsDeductionDto
{
    public int SubCode { get; init; }
    public int AyId { get; init; }
    public int Pcode { get; init; }
    public int Ded80id { get; init; }
    public double Amount { get; init; }
    public double Amount1 { get; init; }
    public double Amount2 { get; init; }
    public double Amount3 { get; init; }
    public double Amount4 { get; init; }
    public double Amount5 { get; init; }
    public double Amount6 { get; init; }
    public double Amount7 { get; init; }
    public double Dedamt { get; init; }
    public double Dedamt2 { get; init; }
    public double Grossamt { get; init; }
    public bool Senior { get; init; }
    public bool Ssenior { get; init; }
    public bool Severe { get; init; }
    public string? Date { get; init; }
    public int Salary_id { get; init; }
}

public sealed record DdodetDto
{
    public int Subcode { get; init; }
    public int Ayid { get; init; }
    public int Period { get; init; }
    public int Aocode { get; init; }
    public int Dcode { get; init; }
    public double Tax { get; init; }
    public double Tds { get; init; }
    public string? Nature { get; init; }
    public string? Mapcode { get; init; }
}

public sealed record F15hnDto
{
    public int Subcode { get; init; }
    public int Ayid { get; init; }
    public int Pcode { get; init; }
    public double Amount { get; init; }
    public string? Desc { get; init; }
    public string? Date { get; init; }
    public string? Nature { get; init; }
    public string? Section { get; init; }
    public double Income { get; init; }
    public string? Quarter { get; init; }
}

public sealed record F15hnPayeeDto
{
    public int Subcode { get; init; }
    public int Ayid { get; init; }
    public int Pcode { get; init; }
    public int Formid { get; init; }
    public string? Date15g { get; init; }
    public string? Date15g2 { get; init; }
    public string? Date15g3 { get; init; }
    public string? Unqno15g { get; init; }
    public int Nof15g { get; init; }
    public double Value15g { get; init; }
    public double Eincome { get; init; }
    public double Cincome { get; init; }
    public double AmtPaid { get; init; }
    public string? Layr { get; init; }
    public string? Type { get; init; }
    public string? Quarter { get; init; }
}
