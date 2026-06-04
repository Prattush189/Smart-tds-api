using System.Security.Claims;
using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Writable assessee columns sent by the desktop (matches MasterEntities.Assessee
/// property names; subcode is identity and prodkey is taken from the JWT, so both
/// are excluded here). Dates (dob/doj/etc.) are dd/MM/yyyy strings in varchar
/// columns — passed straight through, never date-converted.
/// </summary>
public sealed record AssesseeReq
{
    public string? fileCode { get; init; }
    public int? groupCode { get; init; }
    public string? tradeName { get; init; }
    public string? firstName { get; init; }
    public string? middleName { get; init; }
    public string? lastName { get; init; }
    public string? fatherName { get; init; }
    public string? husbandName { get; init; }
    public string? assesseeStatus { get; init; }
    public string? assesseeSubStatus { get; init; }
    public string? dob { get; init; }
    public string? sex { get; init; }
    public string? pan { get; init; }
    public string? panStatus { get; init; }
    public string? tan { get; init; }
    public string? cin { get; init; }
    public string? gstNo { get; init; }
    public string? aadhaarNo { get; init; }
    public string? aadhaarEnrolment { get; init; }
    public string? aadhaarStatus { get; init; }
    public string? sebiRegNo { get; init; }
    public string? principalPan { get; init; }
    public string? citizenshipCode { get; init; }
    public string? citizenshipOth { get; init; }
    public string? residentStatus { get; init; }
    public string? passportNo { get; init; }
    public string? mobilePrimaryStdCode { get; init; }
    public string? mobilePrimary { get; init; }
    public string? mobilePrimaryBelongsTo { get; init; }
    public string? mobileSecondaryStdCode { get; init; }
    public string? mobileSecondary { get; init; }
    public string? mobileSecondaryBelongsTo { get; init; }
    public string? mobileResiStdCode { get; init; }
    public string? mobileResi { get; init; }
    public string? phoneResiStdCode { get; init; }
    public string? phoneResi { get; init; }
    public string? emailPrimary { get; init; }
    public string? emailPrimaryBelongsTo { get; init; }
    public string? emailSecondary { get; init; }
    public string? emailSecondaryBelongsTo { get; init; }
    public string? addr1 { get; init; }
    public string? addr2 { get; init; }
    public string? addr3 { get; init; }
    public string? addr4 { get; init; }
    public int? postOfcCode { get; init; }
    public string? othpostOfcName { get; init; }
    public int? pinCode { get; init; }
    public string? zipCode { get; init; }
    public int? cityCode { get; init; }
    public string? othCityName { get; init; }
    public int? stateCode { get; init; }
    public string? othStateName { get; init; }
    public int? countryCode { get; init; }
    public string? communicationAddrTo { get; init; }
    public string? areaCode { get; init; }
    public string? aoType { get; init; }
    public string? aoNo { get; init; }
    public string? rangeCode { get; init; }
    public string? jurisdiction { get; init; }
    public string? jurisdictionEmail { get; init; }
    public string? jurisdictionBuildingName { get; init; }
    public string? ward { get; init; }
    public bool auditCase { get; init; }
    public string? verifiedBy { get; init; }
    public string? referredBy { get; init; }
    public int? consultantId { get; init; }
    public int? startAY { get; init; }
    public int? endAY { get; init; }
    public string? userId { get; init; }
    public string? password { get; init; }
    public string? tdsCpcPwd { get; init; }
    public string? dscCommonName { get; init; }
    public string? dscExpiryDt { get; init; }
    public string? dscLinkedFlag { get; init; }
    public string? recgnNumAllottedByDPIIT { get; init; }
    public string? certificationNumber { get; init; }
    public string? dateOfFilingForm2 { get; init; }
    public string? lastLogin { get; init; }
    public string? lastLogout { get; init; }
    public string? lastUpdated { get; init; }
    public byte[]? profilePic { get; init; }
    public int CreatedBy { get; init; }
    public DateTime CreatedOn { get; init; }
    public int ModifiedBy { get; init; }
    public DateTime ModifiedOn { get; init; }
    public bool IsDeleted { get; init; }
    public string? leiNo { get; init; }
    public string? leiValidUpto { get; init; }
    public string? PRANNum { get; init; }
    public string? authName { get; init; }
    public string? authDOB { get; init; }
    public string? authPan { get; init; }
    public string? authDesignation { get; init; }
    public string? authAddr1 { get; init; }
    public string? authAddr2 { get; init; }
    public string? authAddr3 { get; init; }
    public string? authCity { get; init; }
    public int? authPin { get; init; }
    public string? authState { get; init; }
    public string? authSex { get; init; }
    public string? authFname { get; init; }
    public string? authStdCode1 { get; init; }
    public string? authMobile1 { get; init; }
    public string? authStdCode2 { get; init; }
    public string? authMobile2 { get; init; }
    public string? authStdPh1 { get; init; }
    public string? authPhone1 { get; init; }
    public string? authStdPh2 { get; init; }
    public string? authPhone2 { get; init; }
    public string? authEmail1 { get; init; }
    public string? authEmail2 { get; init; }
    public string? govState { get; init; }
    public string? govPAO { get; init; }
    public string? govPAOName { get; init; }
    public string? govDDO { get; init; }
    public string? govDDONo { get; init; }
    public string? govMinistryName { get; init; }
    public string? govMinistryNameOth { get; init; }
    public string? govAIN { get; init; }
    public string? applicableForms { get; init; }
    public string? branchName { get; init; }
}

public static class AssesseeEndpoints
{
    // Writable columns (db name = @param). prodkey & subcode handled separately.
    // Note column-name typos in schema: aadhaarnrolment, aadharstatus, leivaldupto.
    private const string ColumnList =
        @"filecode, groupcode, tradename, firstname, middlename, lastname, fathername,
          husbandname, assesseestatus, assesseesubstatus, dob, sex, pan, panstatus, tan,
          cin, gstno, aadhaarno, aadhaarnrolment, aadharstatus, sebiregno, principalpan,
          citizenshipcode, citizenshipoth, residentstatus, passportno, mobileprimarystdcode,
          mobileprimary, mobileprimarybelongsto, mobilesecondarystdcode, mobilesecondary,
          mobilesecondarybelongsto, mobileresistdcode, mobileresi, phoneresistdcode, phoneresi,
          emailprimary, emailprimarybelongsto, emailsecondary, emailsecondarybelongsto,
          addr1, addr2, addr3, addr4, postofccode, othpostofcname, pincode, zipcode, citycode,
          othcityname, statecode, othstatename, countrycode, communicationaddrto, areacode,
          aotype, aono, rangecode, jurisdiction, jurisdictionemail, jurisdictionbuildingname,
          ward, auditcase, verifiedby, referredby, consultantid, startay, enday, userid,
          password, tdscpcpwd, dsccommonname, dscexpirydt, dsclinkedflag, recgnnumallottedbydpiit,
          certificationnumber, dateoffilingform2, lastlogin, lastlogout, lastupdated, profilepic,
          createdby, createdon, modifiedby, modifiedon, isdeleted, leino, leivaldupto, prannum,
          authname, authdob, authpan, authdesignation, authaddr1, authaddr2, authaddr3, authcity,
          authpin, authstate, authsex, authfname, authstdcode1, authmobile1, authstdcode2,
          authmobile2, authstdph1, authphone1, authstdph2, authphone2, authemail1, authemail2,
          govstate, govpao, govpaoname, govddo, govddono, govministryname, govministrynameoth,
          govain, applicableforms, branchname";

    // INSERT VALUES list — order matches ColumnList exactly. prodkey prepended in SQL.
    private const string ValueList =
        @"@fileCode, @groupCode, @tradeName, @firstName, @middleName, @lastName, @fatherName,
          @husbandName, @assesseeStatus, @assesseeSubStatus, @dob, @sex, @pan, @panStatus, @tan,
          @cin, @gstNo, @aadhaarNo, @aadhaarEnrolment, @aadhaarStatus, @sebiRegNo, @principalPan,
          @citizenshipCode, @citizenshipOth, @residentStatus, @passportNo, @mobilePrimaryStdCode,
          @mobilePrimary, @mobilePrimaryBelongsTo, @mobileSecondaryStdCode, @mobileSecondary,
          @mobileSecondaryBelongsTo, @mobileResiStdCode, @mobileResi, @phoneResiStdCode, @phoneResi,
          @emailPrimary, @emailPrimaryBelongsTo, @emailSecondary, @emailSecondaryBelongsTo,
          @addr1, @addr2, @addr3, @addr4, @postOfcCode, @othpostOfcName, @pinCode, @zipCode, @cityCode,
          @othCityName, @stateCode, @othStateName, @countryCode, @communicationAddrTo, @areaCode,
          @aoType, @aoNo, @rangeCode, @jurisdiction, @jurisdictionEmail, @jurisdictionBuildingName,
          @ward, @auditCase, @verifiedBy, @referredBy, @consultantId, @startAY, @endAY, @userId,
          @password, @tdsCpcPwd, @dscCommonName, @dscExpiryDt, @dscLinkedFlag, @recgnNumAllottedByDPIIT,
          @certificationNumber, @dateOfFilingForm2, @lastLogin, @lastLogout, @lastUpdated, @profilePic,
          @CreatedBy, @CreatedOn, @ModifiedBy, @ModifiedOn, @IsDeleted, @leiNo, @leiValidUpto, @PRANNum,
          @authName, @authDOB, @authPan, @authDesignation, @authAddr1, @authAddr2, @authAddr3, @authCity,
          @authPin, @authState, @authSex, @authFname, @authStdCode1, @authMobile1, @authStdCode2,
          @authMobile2, @authStdPh1, @authPhone1, @authStdPh2, @authPhone2, @authEmail1, @authEmail2,
          @govState, @govPAO, @govPAOName, @govDDO, @govDDONo, @govMinistryName, @govMinistryNameOth,
          @govAIN, @applicableForms, @branchName";

    // UPDATE SET list — col = @param pairs, order matches ColumnList.
    private const string SetList =
        @"filecode=@fileCode, groupcode=@groupCode, tradename=@tradeName, firstname=@firstName,
          middlename=@middleName, lastname=@lastName, fathername=@fatherName, husbandname=@husbandName,
          assesseestatus=@assesseeStatus, assesseesubstatus=@assesseeSubStatus, dob=@dob, sex=@sex,
          pan=@pan, panstatus=@panStatus, tan=@tan, cin=@cin, gstno=@gstNo, aadhaarno=@aadhaarNo,
          aadhaarnrolment=@aadhaarEnrolment, aadharstatus=@aadhaarStatus, sebiregno=@sebiRegNo,
          principalpan=@principalPan, citizenshipcode=@citizenshipCode, citizenshipoth=@citizenshipOth,
          residentstatus=@residentStatus, passportno=@passportNo, mobileprimarystdcode=@mobilePrimaryStdCode,
          mobileprimary=@mobilePrimary, mobileprimarybelongsto=@mobilePrimaryBelongsTo,
          mobilesecondarystdcode=@mobileSecondaryStdCode, mobilesecondary=@mobileSecondary,
          mobilesecondarybelongsto=@mobileSecondaryBelongsTo, mobileresistdcode=@mobileResiStdCode,
          mobileresi=@mobileResi, phoneresistdcode=@phoneResiStdCode, phoneresi=@phoneResi,
          emailprimary=@emailPrimary, emailprimarybelongsto=@emailPrimaryBelongsTo,
          emailsecondary=@emailSecondary, emailsecondarybelongsto=@emailSecondaryBelongsTo,
          addr1=@addr1, addr2=@addr2, addr3=@addr3, addr4=@addr4, postofccode=@postOfcCode,
          othpostofcname=@othpostOfcName, pincode=@pinCode, zipcode=@zipCode, citycode=@cityCode,
          othcityname=@othCityName, statecode=@stateCode, othstatename=@othStateName,
          countrycode=@countryCode, communicationaddrto=@communicationAddrTo, areacode=@areaCode,
          aotype=@aoType, aono=@aoNo, rangecode=@rangeCode, jurisdiction=@jurisdiction,
          jurisdictionemail=@jurisdictionEmail, jurisdictionbuildingname=@jurisdictionBuildingName,
          ward=@ward, auditcase=@auditCase, verifiedby=@verifiedBy, referredby=@referredBy,
          consultantid=@consultantId, startay=@startAY, enday=@endAY, userid=@userId, password=@password,
          tdscpcpwd=@tdsCpcPwd, dsccommonname=@dscCommonName, dscexpirydt=@dscExpiryDt,
          dsclinkedflag=@dscLinkedFlag, recgnnumallottedbydpiit=@recgnNumAllottedByDPIIT,
          certificationnumber=@certificationNumber, dateoffilingform2=@dateOfFilingForm2,
          lastlogin=@lastLogin, lastlogout=@lastLogout, lastupdated=@lastUpdated, profilepic=@profilePic,
          createdby=@CreatedBy, createdon=@CreatedOn, modifiedby=@ModifiedBy, modifiedon=@ModifiedOn,
          isdeleted=@IsDeleted, leino=@leiNo, leivaldupto=@leiValidUpto, prannum=@PRANNum,
          authname=@authName, authdob=@authDOB, authpan=@authPan, authdesignation=@authDesignation,
          authaddr1=@authAddr1, authaddr2=@authAddr2, authaddr3=@authAddr3, authcity=@authCity,
          authpin=@authPin, authstate=@authState, authsex=@authSex, authfname=@authFname,
          authstdcode1=@authStdCode1, authmobile1=@authMobile1, authstdcode2=@authStdCode2,
          authmobile2=@authMobile2, authstdph1=@authStdPh1, authphone1=@authPhone1,
          authstdph2=@authStdPh2, authphone2=@authPhone2, authemail1=@authEmail1, authemail2=@authEmail2,
          govstate=@govState, govpao=@govPAO, govpaoname=@govPAOName, govddo=@govDDO, govddono=@govDDONo,
          govministryname=@govMinistryName, govministrynameoth=@govMinistryNameOth, govain=@govAIN,
          applicableforms=@applicableForms, branchname=@branchName";

    public static void MapAssesseeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/assessees").RequireAuthorization();

        // List (full rows, scoped by JWT prodkey — desktop loads all at startup)
        grp.MapGet("/", async (ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct,
            bool includeDeleted = false) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = @"select * from assessee
                        where prodkey = @pk"
                      + (includeDeleted ? "" : " and isdeleted = false")
                      + " order by tradename";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { pk = prodkey }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListAssessees");

        grp.MapGet("/{subCode:int}", async (int subCode, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from assessee where subcode = @subCode and prodkey = @pk";
            var row = await conn.QueryFirstOrDefaultAsync(
                new CommandDefinition(sql, new { subCode, pk = prodkey }, cancellationToken: ct));
            return row is null ? Results.NotFound() : Results.Ok(row);
        }).WithName("GetAssessee");

        // POST /api/assessees — insert all writable columns; prodkey from JWT; returns { id }.
        grp.MapPost("/", async (AssesseeReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"insert into assessee (prodkey, {ColumnList})
                         values (@prodkey, {ValueList})
                         returning subcode";
            var p = ToParams(body);
            p.Add("prodkey", prodkey);
            var newSubcode = await conn.ExecuteScalarAsync<int>(
                new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.Ok(new { id = newSubcode });
        }).WithName("CreateAssessee");

        // PUT /api/assessees/{subCode} — update all writable columns for this prodkey.
        grp.MapPut("/{subCode:int}", async (int subCode, AssesseeReq body, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            var sql = $@"update assessee set {SetList}
                         where subcode = @subCode and prodkey = @prodkey";
            var p = ToParams(body);
            p.Add("subCode", subCode);
            p.Add("prodkey", prodkey);
            await conn.ExecuteAsync(new CommandDefinition(sql, p, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateAssessee");

        // DELETE /api/assessees/{subCode} — hard delete (permanent).
        // Removes the assessee and ALL of its MASTER-DB child rows in one
        // implicit transaction (a multi-statement command runs atomically in PG).
        // NOTE: per-year transactional rows (payee/tdsentry/challan/etc.) live in
        // the separate smarttds<YY> databases and are NOT removed here.
        grp.MapDelete("/{subCode:int}", async (int subCode, ClaimsPrincipal principal, IDbConnectionFactory db, CancellationToken ct) =>
        {
            var prodkey = principal.FindFirstValue("prodkey");
            if (string.IsNullOrEmpty(prodkey))
                return Results.Unauthorized();

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"
                delete from billreceipts     where billid in (select id from billhead where subcode = @subCode);
                delete from billhead         where subcode = @subCode;   -- billdetails cascades
                delete from billmast         where subcode = @subCode;
                delete from billreceipt      where subcode = @subCode;
                delete from bankdetails      where subcode = @subCode;
                delete from assesseerep      where subcode = @subCode;
                delete from assesseeresstatus where subcode = @subCode;
                delete from returndates      where subcode = @subCode;
                delete from feepaidmarking   where subcode = @subCode;
                delete from assessee         where subcode = @subCode and prodkey = @prodkey;";
            await conn.ExecuteAsync(
                new CommandDefinition(sql, new { subCode, prodkey }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteAssessee");
    }

    // Build a DynamicParameters bag from the request. Dates in varchar columns
    // (dob/authdob/etc.) are passed through as the strings the client sent.
    private static DynamicParameters ToParams(AssesseeReq b)
    {
        var p = new DynamicParameters();
        p.Add("fileCode", b.fileCode);
        p.Add("groupCode", b.groupCode);
        p.Add("tradeName", b.tradeName);
        p.Add("firstName", b.firstName);
        p.Add("middleName", b.middleName);
        p.Add("lastName", b.lastName);
        p.Add("fatherName", b.fatherName);
        p.Add("husbandName", b.husbandName);
        p.Add("assesseeStatus", b.assesseeStatus);
        p.Add("assesseeSubStatus", b.assesseeSubStatus);
        p.Add("dob", b.dob);
        p.Add("sex", b.sex);
        p.Add("pan", b.pan);
        p.Add("panStatus", b.panStatus);
        p.Add("tan", b.tan);
        p.Add("cin", b.cin);
        p.Add("gstNo", b.gstNo);
        p.Add("aadhaarNo", b.aadhaarNo);
        p.Add("aadhaarEnrolment", b.aadhaarEnrolment);
        p.Add("aadhaarStatus", b.aadhaarStatus);
        p.Add("sebiRegNo", b.sebiRegNo);
        p.Add("principalPan", b.principalPan);
        p.Add("citizenshipCode", b.citizenshipCode);
        p.Add("citizenshipOth", b.citizenshipOth);
        p.Add("residentStatus", b.residentStatus);
        p.Add("passportNo", b.passportNo);
        p.Add("mobilePrimaryStdCode", b.mobilePrimaryStdCode);
        p.Add("mobilePrimary", b.mobilePrimary);
        p.Add("mobilePrimaryBelongsTo", b.mobilePrimaryBelongsTo);
        p.Add("mobileSecondaryStdCode", b.mobileSecondaryStdCode);
        p.Add("mobileSecondary", b.mobileSecondary);
        p.Add("mobileSecondaryBelongsTo", b.mobileSecondaryBelongsTo);
        p.Add("mobileResiStdCode", b.mobileResiStdCode);
        p.Add("mobileResi", b.mobileResi);
        p.Add("phoneResiStdCode", b.phoneResiStdCode);
        p.Add("phoneResi", b.phoneResi);
        p.Add("emailPrimary", b.emailPrimary);
        p.Add("emailPrimaryBelongsTo", b.emailPrimaryBelongsTo);
        p.Add("emailSecondary", b.emailSecondary);
        p.Add("emailSecondaryBelongsTo", b.emailSecondaryBelongsTo);
        p.Add("addr1", b.addr1);
        p.Add("addr2", b.addr2);
        p.Add("addr3", b.addr3);
        p.Add("addr4", b.addr4);
        p.Add("postOfcCode", b.postOfcCode);
        p.Add("othpostOfcName", b.othpostOfcName);
        p.Add("pinCode", b.pinCode);
        p.Add("zipCode", b.zipCode);
        p.Add("cityCode", b.cityCode);
        p.Add("othCityName", b.othCityName);
        p.Add("stateCode", b.stateCode);
        p.Add("othStateName", b.othStateName);
        p.Add("countryCode", b.countryCode);
        p.Add("communicationAddrTo", b.communicationAddrTo);
        p.Add("areaCode", b.areaCode);
        p.Add("aoType", b.aoType);
        p.Add("aoNo", b.aoNo);
        p.Add("rangeCode", b.rangeCode);
        p.Add("jurisdiction", b.jurisdiction);
        p.Add("jurisdictionEmail", b.jurisdictionEmail);
        p.Add("jurisdictionBuildingName", b.jurisdictionBuildingName);
        p.Add("ward", b.ward);
        p.Add("auditCase", b.auditCase);
        p.Add("verifiedBy", b.verifiedBy);
        p.Add("referredBy", b.referredBy);
        p.Add("consultantId", b.consultantId);
        p.Add("startAY", b.startAY);
        p.Add("endAY", b.endAY);
        p.Add("userId", b.userId);
        p.Add("password", b.password);
        p.Add("tdsCpcPwd", b.tdsCpcPwd);
        p.Add("dscCommonName", b.dscCommonName);
        p.Add("dscExpiryDt", b.dscExpiryDt);
        p.Add("dscLinkedFlag", b.dscLinkedFlag);
        p.Add("recgnNumAllottedByDPIIT", b.recgnNumAllottedByDPIIT);
        p.Add("certificationNumber", b.certificationNumber);
        p.Add("dateOfFilingForm2", b.dateOfFilingForm2);
        p.Add("lastLogin", b.lastLogin);
        p.Add("lastLogout", b.lastLogout);
        p.Add("lastUpdated", b.lastUpdated);
        p.Add("profilePic", b.profilePic);
        p.Add("CreatedBy", b.CreatedBy);
        p.Add("CreatedOn", b.CreatedOn);
        p.Add("ModifiedBy", b.ModifiedBy);
        p.Add("ModifiedOn", b.ModifiedOn);
        p.Add("IsDeleted", b.IsDeleted);
        p.Add("leiNo", b.leiNo);
        p.Add("leiValidUpto", b.leiValidUpto);
        p.Add("PRANNum", b.PRANNum);
        p.Add("authName", b.authName);
        p.Add("authDOB", b.authDOB);
        p.Add("authPan", b.authPan);
        p.Add("authDesignation", b.authDesignation);
        p.Add("authAddr1", b.authAddr1);
        p.Add("authAddr2", b.authAddr2);
        p.Add("authAddr3", b.authAddr3);
        p.Add("authCity", b.authCity);
        p.Add("authPin", b.authPin);
        p.Add("authState", b.authState);
        p.Add("authSex", b.authSex);
        p.Add("authFname", b.authFname);
        p.Add("authStdCode1", b.authStdCode1);
        p.Add("authMobile1", b.authMobile1);
        p.Add("authStdCode2", b.authStdCode2);
        p.Add("authMobile2", b.authMobile2);
        p.Add("authStdPh1", b.authStdPh1);
        p.Add("authPhone1", b.authPhone1);
        p.Add("authStdPh2", b.authStdPh2);
        p.Add("authPhone2", b.authPhone2);
        p.Add("authEmail1", b.authEmail1);
        p.Add("authEmail2", b.authEmail2);
        p.Add("govState", b.govState);
        p.Add("govPAO", b.govPAO);
        p.Add("govPAOName", b.govPAOName);
        p.Add("govDDO", b.govDDO);
        p.Add("govDDONo", b.govDDONo);
        p.Add("govMinistryName", b.govMinistryName);
        p.Add("govMinistryNameOth", b.govMinistryNameOth);
        p.Add("govAIN", b.govAIN);
        p.Add("applicableForms", b.applicableForms ?? "24Q,26Q,27Q,27EQ");
        p.Add("branchName", b.branchName);
        return p;
    }
}
