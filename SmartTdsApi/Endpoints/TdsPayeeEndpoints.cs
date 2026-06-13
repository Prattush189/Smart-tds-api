using Dapper;
using Npgsql;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

// ---------------------------------------------------------------------------
// TdsPayee is a composite READ model: tdsentry (year DB) LEFT JOIN payee
// (year DB) on tdsentry.payeeid = payee.id.
//
// Historically the desktop also joined [MasterDbTds].[dbo].[TdsEntriesSection]
// to resolve the section NAME. PostgreSQL cannot cross-database join and the
// section table lives in the MASTER DB, so we DO NOT join it here. The
// "Section" column below is projected from tdsentry.section (the numeric code,
// as text); the desktop already holds Variables.TdsEntriesSectionList and maps
// section -> name in memory.
// ---------------------------------------------------------------------------

/// <summary>
/// Joined projection matching the SmartTdsEntities.TdsPayee entity field names.
/// Columns are aliased to the exact (case-sensitive) property names so the
/// desktop's JSON deserializer binds them directly.
/// </summary>
public sealed record TdsPayeeDto
{
    public int id { get; init; }
    public int chId { get; init; }
    public int payeeId { get; init; }
    public string? PayeeName { get; init; }
    public int subCode { get; init; }
    public int ayId { get; init; }
    public string? Name { get; init; }
    public string? DatePayment { get; init; }
    public string? DateDeduct { get; init; }
    public double AmtPay { get; init; }
    public double TdsDeduct { get; init; }
    public double SurDeduct { get; init; }
    public double Cess { get; init; }
    public double TotalTds2 { get; init; }
    public string? Pan { get; init; }
    public string? Section { get; init; }
    public string? PanStatus { get; init; }
    public int Paycode { get; init; }
    public bool eValid { get; init; }
    public string? FormType { get; init; }
    public double ActualTds { get; init; }
    public double ChInterest { get; init; }
    public double ChTdsDep { get; init; }
}

public static class TdsPayeeEndpoints
{
    private const string YearHeader = "X-Assessment-Year";

    public static void MapTdsPayeeEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tdspayee").RequireAuthorization();

        // GET /api/tdspayee?subCode=&ayId=&formType=
        // Joins tdsentry (left join payee) in the year DB. formType is optional
        // and filters on tdsentry.formtype when supplied.
        grp.MapGet("/", async (
            HttpRequest http,
            IDbConnectionFactory db,
            CancellationToken ct,
            int subCode,
            int ayId,
            string? formType) =>
        {
            if (!http.Headers.TryGetValue(YearHeader, out var year) || string.IsNullOrWhiteSpace(year))
                return Results.BadRequest(new { error = $"{YearHeader} header is required (e.g. '26')" });

            try
            {
                using var conn = await db.OpenYearAsync(year!, ct);

                var sql = new System.Text.StringBuilder(
                    @"select
                          t.id                              as ""id"",
                          coalesce(t.chid, 0)               as ""chId"",
                          coalesce(t.payeeid, 0)            as ""payeeId"",
                          t.payeename                       as ""PayeeName"",
                          t.subcode                         as ""subCode"",
                          t.ayid                            as ""ayId"",
                          p.name                            as ""Name"",
                          t.datepayment                     as ""DatePayment"",
                          t.datededuct                      as ""DateDeduct"",
                          coalesce(t.amtpay, 0)             as ""AmtPay"",
                          coalesce(t.tdsdeduct, 0)          as ""TdsDeduct"",
                          coalesce(t.surdeduct, 0)          as ""SurDeduct"",
                          coalesce(t.cess, 0)               as ""Cess"",
                          coalesce(t.totaltds2, 0)          as ""TotalTds2"",
                          p.pan                             as ""Pan"",
                          cast(t.section as varchar)        as ""Section"",
                          p.panstatus                       as ""PanStatus"",
                          coalesce(t.pcode, 0)              as ""Paycode"",
                          coalesce(t.evalid, false)         as ""eValid"",
                          t.formtype                        as ""FormType"",
                          coalesce(t.actualtds, 0)          as ""ActualTds"",
                          coalesce(t.chinterest, 0)         as ""ChInterest"",
                          coalesce(t.chtdsdep, 0)           as ""ChTdsDep""
                      from tdsentry t
                      left join payee p on p.id = t.payeeid
                      where t.subcode = @subCode and t.ayid = @ayId");

                var param = new DynamicParameters();
                param.Add("subCode", subCode);
                param.Add("ayId", ayId);

                // "ALL" (the FrmChallan "All Forms" option) means NO form filter — not a
                // literal formtype value. Treating it literally made `formtype = 'ALL'` match
                // zero rows, so the challan-edit grid showed none of its linked entries.
                if (!string.IsNullOrWhiteSpace(formType) && formType.Trim().ToUpperInvariant() != "ALL")
                {
                    sql.Append(" and t.formtype = @formType");
                    param.Add("formType", formType);
                }

                sql.Append(" order by t.id");

                var rows = await conn.QueryAsync<TdsPayeeDto>(
                    new CommandDefinition(sql.ToString(), param, cancellationToken: ct));
                return Results.Ok(rows);
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (PostgresException pe) when (pe.SqlState == "3D000")
            {
                return Results.NotFound(new { error = $"No data for assessment year '{year}' (database not provisioned)." });
            }
        }).WithName("ListTdsPayee");
    }
}
