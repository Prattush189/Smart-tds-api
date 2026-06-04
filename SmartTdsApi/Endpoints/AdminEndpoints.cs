using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ─────────────────────────────────────────────────────────────────────────
// Request DTOs. Property names match the MasterEntities entities 1:1 so the
// BAL can post the entity directly. Identity / server-owned columns (id,
// userid) are excluded; prodkey for users comes from the JWT, not the body.
// ─────────────────────────────────────────────────────────────────────────

/// <summary>Writable users columns. prodkey comes from the JWT; userid is identity.</summary>
public sealed record UserReq
{
    public string? userName { get; init; }
    public string? name { get; init; }
    public string? pwd { get; init; }
    public string? emailId { get; init; }
    public string? mobile { get; init; }
    public string? userType { get; init; }
    public bool assesseeAddFlag { get; init; }
    public bool assesseeEditFlag { get; init; }
    public bool assesseeDeleteFlag { get; init; }
    public bool viewPwdFlag { get; init; }
    public bool backupFlag { get; init; }
    public bool restoreFlag { get; init; }
    public bool efilingFlag { get; init; }
    public bool rptViewFlag { get; init; }
    public bool editFiledReturnFlag { get; init; }
    public int? selectedPer { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
}

/// <summary>Writable bankdetails columns (matches MasterEntities.BankDetails; id is identity).</summary>
public sealed record BankDetailsReq
{
    public int subCode { get; init; }
    public string? bankName { get; init; }
    public string? branchName { get; init; }
    public string? bankAdd { get; init; }
    public string? bankAcNo { get; init; }
    public string? ifscCode { get; init; }
    public string? bsrNo { get; init; }
    public string? micrNo { get; init; }
    public string? typeCode { get; init; }
    public string? ecs { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
    public string? AppliesToYear { get; init; }
}

/// <summary>Writable returndates columns (matches MasterEntities.ReturnDates; id is identity).</summary>
public sealed record ReturnDatesReq
{
    public int subcode { get; init; }
    public int ayid { get; init; }
    public string? quarter { get; init; }
    public string? signingDate { get; init; }
    public string? place { get; init; }
    public string? formName { get; init; }
    public string? tokenNumber { get; init; }
    public bool addressChangeOrg { get; init; }
    public bool addressChangeAuth { get; init; }
    public string? aoApprovalNo { get; init; }
    public bool isRegularStatement { get; init; }
    public bool isNilReturn { get; init; }
    public int nilSectionsCount { get; init; }
}

/// <summary>Writable feepaidmarking columns (matches MasterEntities.FeePaidMarking; id is identity).</summary>
public sealed record FeePaidMarkingReq
{
    public int subCode { get; init; }
    public int fyid { get; init; }
    public int periodId { get; init; }
    public bool feePaid { get; init; }
    public string? notes { get; init; }
    public DateTime createdOn { get; init; }
    public DateTime modifiedOn { get; init; }
}

public static class AdminEndpoints
{
    public static void MapAdminEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api").RequireAuthorization();

        MapUsers(grp);
        MapBankDetails(grp);
        MapReturnDates(grp);
        MapFeePaidMarking(grp);
    }

    // ───────────────────────────── USERS ─────────────────────────────
    // Firm data: scoped by JWT prodkey. PK is (prodkey, username); userid is
    // identity. Passwords are stored exactly as sent (hashing handled elsewhere).
    private static void MapUsers(RouteGroupBuilder grp)
    {
        const string UserColumns =
            @"username, name, pwd, emailid, mobile, usertype, assesseeaddflag, assesseeeditflag,
              assesseedeleteflag, viewpwdflag, backupflag, restoreflag, efilingflag, rptviewflag,
              editfiledreturnflag, selectedper, createdby, createdon, modifiedby, modifiedon, isdeleted";

        const string UserValues =
            @"@userName, @name, @pwd, @emailId, @mobile, @userType, @assesseeAddFlag, @assesseeEditFlag,
              @assesseeDeleteFlag, @viewPwdFlag, @backupFlag, @restoreFlag, @efilingFlag, @rptViewFlag,
              @editFiledReturnFlag, @selectedPer, @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted";

        const string UserSet =
            @"name=@name, pwd=@pwd, emailid=@emailId, mobile=@mobile, usertype=@userType,
              assesseeaddflag=@assesseeAddFlag, assesseeeditflag=@assesseeEditFlag,
              assesseedeleteflag=@assesseeDeleteFlag, viewpwdflag=@viewPwdFlag, backupflag=@backupFlag,
              restoreflag=@restoreFlag, efilingflag=@efilingFlag, rptviewflag=@rptViewFlag,
              editfiledreturnflag=@editFiledReturnFlag, selectedper=@selectedPer, createdby=@CreatedBy,
              createdon=@CreatedOn, modifiedby=@ModifiedBy, modifiedon=@ModifiedOn, isdeleted=@IsDeleted";

        // GET /api/users — full rows scoped by JWT prodkey, undeleted only.
        grp.MapGet("/users", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey)) return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from users where prodkey = @pk and isdeleted = false order by username";
            var rows = await conn.QueryAsync(new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListUsers");

        // GET /api/users/{username} — single row by PK (prodkey from JWT).
        grp.MapGet("/users/{username}", async (string username, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey)) return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from users where prodkey = @pk and username = @username";
            var row = await conn.QueryFirstOrDefaultAsync(
                new CommandDefinition(sql, new { pk = prodkey, username }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetUser");

        // POST /api/users — insert; prodkey from JWT; PK is (prodkey, username).
        // Returns { id } = the new userid.
        grp.MapPost("/users", async (UserReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey)) return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into users (prodkey, {UserColumns})
                         values (@prodkey, {UserValues})
                         returning userid";
            var p = UserParams(body);
            p.Add("prodkey", prodkey);
            var newId = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateUser");

        // PUT /api/users/{username} — update by PK (prodkey from JWT).
        grp.MapPut("/users/{username}", async (string username, UserReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey)) return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update users set {UserSet}
                         where prodkey = @prodkey and username = @key_username";
            var p = UserParams(body);
            p.Add("prodkey", prodkey);
            p.Add("key_username", username);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateUser");

        // DELETE /api/users/{username} — soft delete (prodkey from JWT).
        grp.MapDelete("/users/{username}", async (string username, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey)) return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from users where prodkey = @prodkey and username = @username";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { prodkey, username }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteUser");
    }

    // ──────────────────────────── BANKDETAILS ────────────────────────────
    // Assessee-owned (no prodkey column): scoped by subcode like the legacy.
    private static void MapBankDetails(RouteGroupBuilder grp)
    {
        const string BankColumns =
            @"subcode, bankname, branchname, bankadd, bankacno, ifsccode, bsrno, micrno, typecode,
              ecs, createdby, createdon, modifiedby, modifiedon, isdeleted, appliestoyear";

        const string BankValues =
            @"@subCode, @bankName, @branchName, @bankAdd, @bankAcNo, @ifscCode, @bsrNo, @micrNo, @typeCode,
              @ecs, @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted, @AppliesToYear";

        const string BankSet =
            @"subcode=@subCode, bankname=@bankName, branchname=@branchName, bankadd=@bankAdd,
              bankacno=@bankAcNo, ifsccode=@ifscCode, bsrno=@bsrNo, micrno=@micrNo, typecode=@typeCode,
              ecs=@ecs, createdby=@CreatedBy, createdon=@CreatedOn, modifiedby=@ModifiedBy,
              modifiedon=@ModifiedOn, isdeleted=@IsDeleted, appliestoyear=@AppliesToYear";

        // GET /api/bankdetails?subCode= — full rows, undeleted only.
        grp.MapGet("/bankdetails", async (int subCode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from bankdetails where subcode = @subCode and isdeleted = false order by id";
            var rows = await conn.QueryAsync(new CommandDefinition(sql, new { subCode }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListBankDetails");

        // GET /api/bankdetails/{id}
        grp.MapGet("/bankdetails/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from bankdetails where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetBankDetails");

        // POST /api/bankdetails — insert; returns { id }.
        grp.MapPost("/bankdetails", async (BankDetailsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into bankdetails ({BankColumns})
                         values ({BankValues})
                         returning id";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, BankParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateBankDetails");

        // PUT /api/bankdetails/{id}
        grp.MapPut("/bankdetails/{id:int}", async (int id, BankDetailsReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update bankdetails set {BankSet} where id = @id";
            var p = BankParams(body);
            p.Add("id", id);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateBankDetails");

        // DELETE /api/bankdetails/{id} — soft delete.
        grp.MapDelete("/bankdetails/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from bankdetails where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteBankDetails");
    }

    // ──────────────────────────── RETURNDATES ────────────────────────────
    // Assessee-owned (no prodkey / isdeleted column): scoped by subcode + ayid.
    // Unique index on (subcode, ayid, quarter, formname); BAL Save() does its own
    // get-then-insert-or-update so we keep a plain insert here.
    private static void MapReturnDates(RouteGroupBuilder grp)
    {
        const string RdColumns =
            @"subcode, ayid, quarter, signingdate, place, formname, tokennumber, addresschangeorg,
              addresschangeauth, aoapprovalnu, isregularstatement, isnilreturn, nilsectionscount";

        const string RdValues =
            @"@subcode, @ayid, @quarter, @signingDate, @place, @formName, @tokenNumber, @addressChangeOrg,
              @addressChangeAuth, @aoApprovalNo, @isRegularStatement, @isNilReturn, @nilSectionsCount";

        const string RdSet =
            @"subcode=@subcode, ayid=@ayid, quarter=@quarter, signingdate=@signingDate, place=@place,
              formname=@formName, tokennumber=@tokenNumber, addresschangeorg=@addressChangeOrg,
              addresschangeauth=@addressChangeAuth, aoapprovalnu=@aoApprovalNo,
              isregularstatement=@isRegularStatement, isnilreturn=@isNilReturn,
              nilsectionscount=@nilSectionsCount";

        // GET /api/returndates?subCode=&ayId= — full rows.
        grp.MapGet("/returndates", async (int subCode, int ayId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from returndates where subcode = @subCode and ayid = @ayId order by id";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode, ayId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListReturnDates");

        // GET /api/returndates/{id}
        grp.MapGet("/returndates/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from returndates where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetReturnDates");

        // POST /api/returndates — insert; returns { id }.
        grp.MapPost("/returndates", async (ReturnDatesReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into returndates ({RdColumns})
                         values ({RdValues})
                         returning id";
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, RdParams(body), cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateReturnDates");

        // PUT /api/returndates/{id}
        grp.MapPut("/returndates/{id:int}", async (int id, ReturnDatesReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update returndates set {RdSet} where id = @id";
            var p = RdParams(body);
            p.Add("id", id);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateReturnDates");

        // DELETE /api/returndates/{id} — hard delete (legacy deletes the row).
        grp.MapDelete("/returndates/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from returndates where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteReturnDates");
    }

    // ─────────────────────────── FEEPAIDMARKING ───────────────────────────
    // Assessee-owned (no prodkey / isdeleted column): scoped by subcode + fyid.
    private static void MapFeePaidMarking(RouteGroupBuilder grp)
    {
        // GET /api/feepaidmarking?subCode=&fyId= — full rows. subCode is optional:
        // when omitted the rows are scoped by fyId only (legacy GetAllList(fyid)).
        grp.MapGet("/feepaidmarking", async (int? subCode, int fyId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"select * from feepaidmarking
                                 where fyid = @fyId and (@subCode is null or subcode = @subCode)
                                 order by id";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { subCode, fyId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListFeePaidMarking");

        // GET /api/feepaidmarking/{id}
        grp.MapGet("/feepaidmarking/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from feepaidmarking where id = @id";
            var row = await conn.QueryFirstOrDefaultAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetFeePaidMarking");

        // POST /api/feepaidmarking — insert; returns { id }.
        grp.MapPost("/feepaidmarking", async (FeePaidMarkingReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into feepaidmarking (subcode, fyid, periodid, feepaid, notes, createdon, modifiedon)
                                 values (@subCode, @fyid, @periodId, @feePaid, @notes, @createdOn, @modifiedOn)
                                 returning id";
            var newId = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql,
                new { body.subCode, body.fyid, body.periodId, body.feePaid, body.notes, body.createdOn, body.modifiedOn },
                cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateFeePaidMarking");

        // PUT /api/feepaidmarking/{id}
        grp.MapPut("/feepaidmarking/{id:int}", async (int id, FeePaidMarkingReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update feepaidmarking
                                 set subcode=@subCode, fyid=@fyid, periodid=@periodId, feepaid=@feePaid,
                                     notes=@notes, modifiedon=@modifiedOn
                                 where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(
                sql,
                new { id, body.subCode, body.fyid, body.periodId, body.feePaid, body.notes, body.modifiedOn },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateFeePaidMarking");

        // DELETE /api/feepaidmarking/{id} — hard delete (no isdeleted column).
        grp.MapDelete("/feepaidmarking/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from feepaidmarking where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteFeePaidMarking");
    }

    // ───────────────────────────── param builders ─────────────────────────────
    private static DynamicParameters UserParams(UserReq b)
    {
        var p = new DynamicParameters();
        p.Add("userName", b.userName);
        p.Add("name", b.name);
        p.Add("pwd", b.pwd);
        p.Add("emailId", b.emailId);
        p.Add("mobile", b.mobile);
        p.Add("userType", b.userType);
        p.Add("assesseeAddFlag", b.assesseeAddFlag);
        p.Add("assesseeEditFlag", b.assesseeEditFlag);
        p.Add("assesseeDeleteFlag", b.assesseeDeleteFlag);
        p.Add("viewPwdFlag", b.viewPwdFlag);
        p.Add("backupFlag", b.backupFlag);
        p.Add("restoreFlag", b.restoreFlag);
        p.Add("efilingFlag", b.efilingFlag);
        p.Add("rptViewFlag", b.rptViewFlag);
        p.Add("editFiledReturnFlag", b.editFiledReturnFlag);
        p.Add("selectedPer", b.selectedPer);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        return p;
    }

    private static DynamicParameters BankParams(BankDetailsReq b)
    {
        var p = new DynamicParameters();
        p.Add("subCode", b.subCode);
        p.Add("bankName", b.bankName);
        p.Add("branchName", b.branchName);
        p.Add("bankAdd", b.bankAdd);
        p.Add("bankAcNo", b.bankAcNo);
        p.Add("ifscCode", b.ifscCode);
        p.Add("bsrNo", b.bsrNo);
        p.Add("micrNo", b.micrNo);
        p.Add("typeCode", b.typeCode);
        p.Add("ecs", b.ecs);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        p.Add("AppliesToYear", b.AppliesToYear);
        return p;
    }

    private static DynamicParameters RdParams(ReturnDatesReq b)
    {
        var p = new DynamicParameters();
        p.Add("subcode", b.subcode);
        p.Add("ayid", b.ayid);
        p.Add("quarter", b.quarter);
        p.Add("signingDate", b.signingDate);
        p.Add("place", b.place);
        p.Add("formName", b.formName);
        p.Add("tokenNumber", b.tokenNumber);
        p.Add("addressChangeOrg", b.addressChangeOrg);
        p.Add("addressChangeAuth", b.addressChangeAuth);
        p.Add("aoApprovalNo", b.aoApprovalNo);
        p.Add("isRegularStatement", b.isRegularStatement);
        p.Add("isNilReturn", b.isNilReturn);
        p.Add("nilSectionsCount", b.nilSectionsCount);
        return p;
    }
}
