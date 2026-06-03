using Dapper;
using SmartTdsApi.Data;

namespace SmartTdsApi.Endpoints;

/// <summary>
/// Writable aymaster date-extension columns. These are dd/MM/yyyy VARCHAR(10)
/// columns in the schema, so they are accepted as strings and stored verbatim
/// (the desktop BAL formats its DateTime values as "dd/MM/yyyy" before sending).
/// </summary>
public sealed record AyMasterWriteReq
{
    public string? NonBusInc { get; init; }
    public string? BusInc { get; init; }
    public string? AuditCase { get; init; }
    public string? CompCase { get; init; }
    public string? Case94E { get; init; }
    public string? AdvInst1 { get; init; }
    public string? AdvInst2 { get; init; }
    public string? AdvInst3 { get; init; }
    public string? AdvInst4 { get; init; }
    public string? UpdNonBusInc { get; init; }
    public string? UpdBusInc { get; init; }
    public string? UpdAuditCase { get; init; }
    public string? UpdCompCase { get; init; }
    public string? UpdCase94E { get; init; }
}

public static class AyMasterWriteEndpoints
{
    public static void MapAyMasterWriteEndpoints(this IEndpointRouteBuilder app)
    {
        var grp = app.MapGroup("/api/masters").RequireAuthorization();

        // PUT /api/masters/aymaster/{id} — update the date-extension columns (stored as dd/MM/yyyy strings).
        grp.MapPut("/aymaster/{id:int}", async (int id, AyMasterWriteReq body, IDbConnectionFactory db, CancellationToken ct) =>
        {
            using var conn = await db.OpenMasterAsync(ct);
            const string sql = @"update aymaster
                                 set nonbusinc = @NonBusInc, businc = @BusInc, auditcase = @AuditCase,
                                     compcase = @CompCase, case94e = @Case94E,
                                     advinst1 = @AdvInst1, advinst2 = @AdvInst2, advinst3 = @AdvInst3, advinst4 = @AdvInst4,
                                     updnonbusinc = @UpdNonBusInc, updbusinc = @UpdBusInc, updauditcase = @UpdAuditCase,
                                     updcompcase = @UpdCompCase, updcase94e = @UpdCase94E
                                 where id = @id";
            await conn.ExecuteAsync(new CommandDefinition(
                sql,
                new
                {
                    id,
                    body.NonBusInc, body.BusInc, body.AuditCase, body.CompCase, body.Case94E,
                    body.AdvInst1, body.AdvInst2, body.AdvInst3, body.AdvInst4,
                    body.UpdNonBusInc, body.UpdBusInc, body.UpdAuditCase, body.UpdCompCase, body.UpdCase94E
                },
                cancellationToken: ct));
            return Results.NoContent();
        }).WithName("UpdateAyMaster");
    }
}
