using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Writable consultant columns (matches MasterEntities.Consultant property names;
/// conscode is identity and prodkey is taken from the JWT, so both are excluded).
/// </summary>
public sealed record ConsultantReq
{
    public string? name { get; init; }
    public string? residenceNo { get; init; }
    public string? residenceName { get; init; }
    public string? roadOrStreet { get; init; }
    public string? localityOrArea { get; init; }
    public string? city { get; init; }
    public string? stateCode { get; init; }
    public string? state { get; init; }
    public string? phoneOffice { get; init; }
    public string? phoneResi { get; init; }
    public string? mobile { get; init; }
    public string? mobile2 { get; init; }
    public string? email { get; init; }
    public string? partnerName { get; init; }
    public string? membership { get; init; }
    public string? partnerDesignation { get; init; }
    public string? slogan { get; init; }
    public string? bankName { get; init; }
    public string? accNo { get; init; }
    public string? ifscCode { get; init; }
    public string? panFirm { get; init; }
    public string? frnNo { get; init; }
    public string? panPArtner { get; init; }
    public int pin { get; init; }
    public string? gstno { get; init; }
    public string? userId { get; init; }
    public string? pwd { get; init; }
    public string? emailProvider { get; init; }
    public string? emailId { get; init; }
    public string? emailPwd { get; init; }
    public bool flagDefault { get; init; }
    public string? logo { get; init; }
    public string? emailSignature { get; init; }
    public bool flagPendingBillsNotifications { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
}

/// <summary>
/// Writable group columns (matches MasterEntities.Group; grpcode is identity and
/// prodkey comes from the JWT).
/// </summary>
public sealed record GroupReq
{
    public string? groupname { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
    public string? email { get; init; }
    public string? mobile { get; init; }
}

public static class FirmDataEndpoints
{
    // Consultant writable columns / values / set lists (order aligned).
    private const string ConsultantColumns =
        @"name, residenceno, residencename, roadorstreet, localityorarea, city, statecode,
          state, phoneoffice, phoneresi, mobile, mobile2, email, partnername, membership,
          partnerdesignation, slogan, bankname, accno, ifsccode, panfirm, frnno, panpartner,
          pin, gstno, userid, pwd, emailprovider, emailid, emailpwd, flagdefault, logo,
          emailsignature, flagpendingbillsnotifications, createdby, createdon, modifiedby,
          modifiedon, isdeleted";

    private const string ConsultantValues =
        @"@name, @residenceNo, @residenceName, @roadOrStreet, @localityOrArea, @city, @stateCode,
          @state, @phoneOffice, @phoneResi, @mobile, @mobile2, @email, @partnerName, @membership,
          @partnerDesignation, @slogan, @bankName, @accNo, @ifscCode, @panFirm, @frnNo, @panPArtner,
          @pin, @gstno, @userId, @pwd, @emailProvider, @emailId, @emailPwd, @flagDefault, @logo,
          @emailSignature, @flagPendingBillsNotifications, @CreatedBy, @CreatedOn, @ModifiedBy,
          @ModifiedOn, @IsDeleted";

    private const string ConsultantSet =
        @"name=@name, residenceno=@residenceNo, residencename=@residenceName, roadorstreet=@roadOrStreet,
          localityorarea=@localityOrArea, city=@city, statecode=@stateCode, state=@state,
          phoneoffice=@phoneOffice, phoneresi=@phoneResi, mobile=@mobile, mobile2=@mobile2,
          email=@email, partnername=@partnerName, membership=@membership,
          partnerdesignation=@partnerDesignation, slogan=@slogan, bankname=@bankName, accno=@accNo,
          ifsccode=@ifscCode, panfirm=@panFirm, frnno=@frnNo, panpartner=@panPArtner, pin=@pin,
          gstno=@gstno, userid=@userId, pwd=@pwd, emailprovider=@emailProvider, emailid=@emailId,
          emailpwd=@emailPwd, flagdefault=@flagDefault, logo=@logo, emailsignature=@emailSignature,
          flagpendingbillsnotifications=@flagPendingBillsNotifications, createdby=@CreatedBy,
          createdon=@CreatedOn, modifiedby=@ModifiedBy, modifiedon=@ModifiedOn, isdeleted=@IsDeleted";

    private const string GroupColumns =
        @"groupname, createdby, createdon, modifiedby, modifiedon, isdeleted, email, mobile";

    private const string GroupValues =
        @"@groupname, @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted, @email, @mobile";

    private const string GroupSet =
        @"groupname=@groupname, createdby=@CreatedBy, createdon=@CreatedOn, modifiedby=@ModifiedBy,
          modifiedon=@ModifiedOn, isdeleted=@IsDeleted, email=@email, mobile=@mobile";

    public static void MapFirmDataEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api").RequireAuthorization();

        // GET /api/consultants — full rows scoped by JWT prodkey
        grp.MapGet("/consultants", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from consultant where prodkey = @pk and isdeleted = false order by name";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListConsultants");

        // GET /api/groups — full rows scoped by JWT prodkey
        grp.MapGet("/groups", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from groups where prodkey = @pk and isdeleted = false order by groupname";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListGroups");

        // ---- Consultant single-row CRUD (scoped by JWT prodkey) ----

        // GET /api/consultants/{id}
        grp.MapGet("/consultants/{id:int}", async (int id, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from consultant where conscode = @id and prodkey = @pk";
            var row = await conn.QueryFirstOrDefaultAsync(
                new CommandDefinition(sql, new { id, pk = prodkey }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetConsultant");

        // POST /api/consultants — prodkey from JWT; returns { id }.
        grp.MapPost("/consultants", async (ConsultantReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into consultant (prodkey, {ConsultantColumns})
                         values (@prodkey, {ConsultantValues})
                         returning conscode";
            var p = ConsultantParams(body);
            p.Add("prodkey", prodkey);
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateConsultant");

        // PUT /api/consultants/{id}
        grp.MapPut("/consultants/{id:int}", async (int id, ConsultantReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update consultant set {ConsultantSet}
                         where conscode = @id and prodkey = @prodkey";
            var p = ConsultantParams(body);
            p.Add("id", id);
            p.Add("prodkey", prodkey);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateConsultant");

        // DELETE /api/consultants/{id} — soft delete.
        grp.MapDelete("/consultants/{id:int}", async (int id, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "update consultant set isdeleted = true where conscode = @id and prodkey = @prodkey";
            await conn.ExecuteAsync(
                new CommandDefinition(sql, new { id, prodkey }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteConsultant");

        // ---- Group single-row CRUD (scoped by JWT prodkey) ----

        // GET /api/groups/{id}
        grp.MapGet("/groups/{id:int}", async (int id, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from groups where grpcode = @id and prodkey = @pk";
            var row = await conn.QueryFirstOrDefaultAsync(
                new CommandDefinition(sql, new { id, pk = prodkey }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetGroup");

        // POST /api/groups — prodkey from JWT; returns { id }.
        grp.MapPost("/groups", async (GroupReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into groups (prodkey, {GroupColumns})
                         values (@prodkey, {GroupValues})
                         returning grpcode";
            var p = GroupParams(body);
            p.Add("prodkey", prodkey);
            var newId = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.Ok(new { id = newId });
        }).WithName("CreateGroup");

        // PUT /api/groups/{id}
        grp.MapPut("/groups/{id:int}", async (int id, GroupReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update groups set {GroupSet}
                         where grpcode = @id and prodkey = @prodkey";
            var p = GroupParams(body);
            p.Add("id", id);
            p.Add("prodkey", prodkey);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateGroup");

        // DELETE /api/groups/{id} — soft delete.
        grp.MapDelete("/groups/{id:int}", async (int id, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "update groups set isdeleted = true where grpcode = @id and prodkey = @prodkey";
            await conn.ExecuteAsync(
                new CommandDefinition(sql, new { id, prodkey }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteGroup");
    }

    private static DynamicParameters ConsultantParams(ConsultantReq b)
    {
        var p = new DynamicParameters();
        p.Add("name", b.name);
        p.Add("residenceNo", b.residenceNo);
        p.Add("residenceName", b.residenceName);
        p.Add("roadOrStreet", b.roadOrStreet);
        p.Add("localityOrArea", b.localityOrArea);
        p.Add("city", b.city);
        p.Add("stateCode", b.stateCode);
        p.Add("state", b.state);
        p.Add("phoneOffice", b.phoneOffice);
        p.Add("phoneResi", b.phoneResi);
        p.Add("mobile", b.mobile);
        p.Add("mobile2", b.mobile2);
        p.Add("email", b.email);
        p.Add("partnerName", b.partnerName);
        p.Add("membership", b.membership);
        p.Add("partnerDesignation", b.partnerDesignation);
        p.Add("slogan", b.slogan);
        p.Add("bankName", b.bankName);
        p.Add("accNo", b.accNo);
        p.Add("ifscCode", b.ifscCode);
        p.Add("panFirm", b.panFirm);
        p.Add("frnNo", b.frnNo);
        p.Add("panPArtner", b.panPArtner);
        p.Add("pin", b.pin);
        p.Add("gstno", b.gstno);
        p.Add("userId", b.userId);
        p.Add("pwd", b.pwd);
        p.Add("emailProvider", b.emailProvider);
        p.Add("emailId", b.emailId);
        p.Add("emailPwd", b.emailPwd);
        p.Add("flagDefault", b.flagDefault);
        p.Add("logo", b.logo);
        p.Add("emailSignature", b.emailSignature);
        p.Add("flagPendingBillsNotifications", b.flagPendingBillsNotifications);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        return p;
    }

    private static DynamicParameters GroupParams(GroupReq b)
    {
        var p = new DynamicParameters();
        p.Add("groupname", b.groupname);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        p.Add("email", b.email);
        p.Add("mobile", b.mobile);
        return p;
    }
}
