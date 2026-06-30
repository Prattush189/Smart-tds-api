using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// TRACES download-request register (master table `tracesrequest`). One row per Form
/// 16/16A/27D/Conso/Justification request raised on TRACES — its request number and,
/// once downloaded, the saved file path. Tenant-isolated by subcode (RLS keys on
/// app.prodkey via app_owns_subcode, set by the connection factory — no manual scoping).
/// Property names match the desktop TracesRequest entity; id/createdon/updatedon are
/// server-managed.
/// </summary>
public sealed record TracesRequestReq
{
    public int subCode { get; init; }
    public string? tan { get; init; }
    public string? requestType { get; init; }
    public string? frmNo { get; init; }
    public string? finYr { get; init; }
    public string? quarter { get; init; }
    public string? requestNo { get; init; }
    public DateTime? requestDate { get; init; }
    public string? status { get; init; }
    public string? filePath { get; init; }
    public DateTime? downloadedOn { get; init; }
    public string? remarks { get; init; }
}

public static class TracesRequestEndpoints
{
    public static void MapTracesRequestEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/tracesrequests").RequireAuthorization();

        // GET /api/tracesrequests[?subCode=] — newest first; optional payer filter.
        // RLS already limits rows to the current tenant's subcodes.
        grp.MapGet("/", async (int? subCode, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            var sql = (subCode.HasValue && subCode.Value > 0)
                ? "select * from tracesrequest where subcode = @subCode order by id desc"
                : "select * from tracesrequest order by id desc";
            var rows = await conn.QueryAsync(new CommandDefinition(sql, new { subCode }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListTracesRequests");

        // POST /api/tracesrequests — insert; createdon/updatedon = now(); returns { id }.
        grp.MapPost("/", async (TracesRequestReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            if (body.subCode <= 0) return Results.BadRequest(new { error = "subCode is required" });
            if (string.IsNullOrWhiteSpace(body.requestType)) return Results.BadRequest(new { error = "requestType is required" });
            if (string.IsNullOrWhiteSpace(body.finYr)) return Results.BadRequest(new { error = "finYr is required" });

            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"
                insert into tracesrequest
                    (subcode, tan, requesttype, frmno, finyr, quarter, requestno,
                     requestdate, status, filepath, downloadedon, remarks, createdon, updatedon)
                values
                    (@subCode, @tan, @requestType, @frmNo, @finYr, @quarter, @requestNo,
                     @requestDate, coalesce(@status, 'Requested'), @filePath, @downloadedOn, @remarks, now(), now())
                returning id";
            var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, body, cancellationToken: ct));
            return Results.Ok(new { id });
        }).WithName("CreateTracesRequest");

        // PUT /api/tracesrequests/{id} — update; updatedon = now(). status falls back to
        // the existing value when not supplied (coalesce) so a partial update can't blank it.
        grp.MapPut("/{id:int}", async (int id, TracesRequestReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"
                update tracesrequest set
                    subcode = @subCode, tan = @tan, requesttype = @requestType, frmno = @frmNo,
                    finyr = @finYr, quarter = @quarter, requestno = @requestNo, requestdate = @requestDate,
                    status = coalesce(@status, status), filepath = @filePath, downloadedon = @downloadedOn,
                    remarks = @remarks, updatedon = now()
                where id = @id";
            var n = await conn.ExecuteAsync(new CommandDefinition(sql,
                new
                {
                    id, body.subCode, body.tan, body.requestType, body.frmNo, body.finYr, body.quarter,
                    body.requestNo, body.requestDate, body.status, body.filePath, body.downloadedOn, body.remarks
                },
                cancellationToken: ct));
            return n == 0 ? Results.NotFound(new { error = $"TRACES request id {id} not found." }) : Results.NoContent();
        }).WithName("UpdateTracesRequest");

        // DELETE /api/tracesrequests/{id} — removes the register row (not the file on disk).
        grp.MapDelete("/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            await conn.ExecuteAsync(new CommandDefinition(
                "delete from tracesrequest where id = @id", new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteTracesRequest");
    }
}
