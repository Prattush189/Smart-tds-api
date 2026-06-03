using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Writable assesseeresstatus columns sent by the desktop (matches
/// MasterEntities.AssesseeResStatus property names; id is identity). This table
/// has no prodkey column, so rows are scoped by ayid only — matching the legacy.
/// modifiedon is set to now() on the server.
/// </summary>
public sealed record AssesseeResStatusReq
{
    public int subCode { get; init; }
    public int ayId { get; init; }
    public string? resStatus { get; init; }
    public string? resStatusVal { get; init; }
}

public static class AssesseeResStatusEndpoints
{
    public static void MapAssesseeResStatusEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/assesseeresstatus").RequireAuthorization();

        // GET /api/assesseeresstatus?ayId= — full rows for an assessment year.
        grp.MapGet("/", async (int ayId, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "select * from assesseeresstatus where ayid = @ayId order by id";
            var rows = await conn.QueryAsync(
                new CommandDefinition(sql, new { ayId }, cancellationToken: ct));
            return Results.Ok(rows);
        }).WithName("ListAssesseeResStatus");

        // POST /api/assesseeresstatus — insert; modifiedon=now(); returns { id }.
        grp.MapPost("/", async (AssesseeResStatusReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"insert into assesseeresstatus (subcode, ayid, resstatus, modifiedon, resstatusval)
                                 values (@subCode, @ayId, @resStatus, now(), @resStatusVal)
                                 returning id";
            var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(
                sql,
                new { body.subCode, body.ayId, body.resStatus, body.resStatusVal },
                cancellationToken: ct));
            return Results.Ok(new { id });
        }).WithName("CreateAssesseeResStatus");

        // PUT /api/assesseeresstatus/{id} — update; modifiedon=now().
        grp.MapPut("/{id:int}", async (int id, AssesseeResStatusReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update assesseeresstatus
                                 set subcode = @subCode, ayid = @ayId, resstatus = @resStatus,
                                     modifiedon = now(), resstatusval = @resStatusVal
                                 where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(
                sql,
                new { id, body.subCode, body.ayId, body.resStatus, body.resStatusVal },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateAssesseeResStatus");

        // DELETE /api/assesseeresstatus/{id} — hard delete (no isdeleted column).
        grp.MapDelete("/{id:int}", async (int id, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = "delete from assesseeresstatus where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(sql, new { id }, cancellationToken: ct));
            return Results.NoContent();
        }).WithName("DeleteAssesseeResStatus");
    }
}
