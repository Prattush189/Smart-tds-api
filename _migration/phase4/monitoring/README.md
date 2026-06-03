# SmartTds HA — Monitoring & Alerting

What to watch on the PostgreSQL 16 + Patroni + PgBouncer + HAProxy stack, the
exact queries/commands to collect each signal, and the alert thresholds. Wire
these into Prometheus (postgres_exporter + patroni metrics + pgbouncer_exporter
+ haproxy stats) or any agent (Zabbix/Netdata/aaPanel). Thresholds below assume
the production 8 vCPU / 32 GB nodes; relax for the 4c/8GB staging VPS.

---

## 1. Replication lag (MOST IMPORTANT for zero-data-loss claim)

Run on the **primary**:

```sql
SELECT
  client_addr,
  application_name,
  state,                         -- expect 'streaming'
  sync_state,                    -- expect 'sync' for the synchronous standby
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)    AS send_lag_bytes,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)  AS replay_lag_bytes,
  write_lag, flush_lag, replay_lag                   -- time intervals
FROM pg_stat_replication;
```

Time-based lag on the **standby**:

```sql
SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;
```

| Signal | Warning | Critical |
|---|---|---|
| `replay_lag` (time) | > 5 s | **> 10 s** |
| `replay_lag_bytes` | > 64 MB | > 256 MB |
| `sync_state` of intended standby | not `sync` for > 30 s | not `sync` for > 60 s |
| `state` | not `streaming` | down / row missing |
| count(*) in pg_stat_replication | < 1 (no standby connected) → **critical** | |

> If `sync_state` is never `sync`, synchronous replication is NOT in effect and
> the RPO=0 guarantee is broken — page immediately.

---

## 2. Patroni cluster state

```bash
# Human view:
patronictl -c /etc/patroni/patroni.yml list smarttds
# Expect exactly one "Leader", others "Replica", all "running",
# and "Sync Standby" present (synchronous_mode=true).

# Machine view (HTTP, scrape these):
curl -s http://10.0.0.11:8008/patroni | jq '{role,state,timeline,sync_standby}'
curl -s http://10.0.0.11:8008/cluster | jq '.members[] | {name,role,state,lag}'
```

| Signal | Alert |
|---|---|
| No node returns `role=master` (no leader) | **critical** — cluster has no primary |
| Two nodes claim leader | **critical** — possible split-brain (check watchdog/etcd) |
| Any member `state != running` | warning, critical if > 2 min |
| `timeline` increased unexpectedly | info — a failover happened; investigate cause |
| Patroni REST :8008 unreachable | critical (HAProxy can't route writes) |

Also watch **etcd** (the DCS): if etcd loses quorum Patroni cannot elect a
leader. Scrape `etcdctl endpoint health` / `etcd_server_has_leader` == 1.

---

## 3. PgBouncer pools (deadline login-storm health)

Connect to the admin console: `psql -h 127.0.0.1 -p 6432 -U pgb_stats pgbouncer`

```sql
SHOW POOLS;     -- per (database,user): cl_active, cl_waiting, sv_active, sv_idle
SHOW STATS;     -- per database: total_xact, total_query, avg_query_time
SHOW LISTS;     -- totals: clients, servers, pools
```

| Column / signal | Warning | Critical |
|---|---|---|
| `cl_waiting` (clients queued for a server conn) | > 0 sustained 30 s | > 0 sustained 2 min → pool exhausted |
| `maxwait` (sec a client has waited) | > 1 s | > 5 s |
| total clients vs `max_client_conn` (1000) | > 80% | > 95% (risk of refusals) |
| `sv_active` near pool_size for a (user,db) | at pool_size | persistently maxed → raise pool_size |

> Remember pools are **per (user,db)**. A spike on `smarttds26` doesn't borrow
> capacity from `masterdbtds`. Size with that in mind (see pgbouncer.ini).

---

## 4. Node / HAProxy health

```bash
# HAProxy backend states (CSV) — alert if any server is "DOWN":
echo "show stat" | socat stdio /var/run/haproxy.sock | cut -d, -f1,2,18
# Or scrape the stats page: http://<haproxy>:7000/  (and :7000/;csv)
```

| Signal | Alert |
|---|---|
| `postgres_write` backend has 0 UP servers | **critical** — no writable target |
| `postgres_read` backend has 0 UP servers | warning — reads falling back to primary |
| `api_nodes` < 2 UP | warning; 0 UP → critical |
| HAProxy process down | critical (use the keepalived VIP failover) |

OS-level per node: CPU > 85% (5 min), RAM/swap (swap-in > 0 is bad with our
shared_buffers sizing), disk usage on `$PGDATA` and WAL/archive dir > 80%,
disk latency on NVMe.

---

## 5. PostgreSQL internals

```sql
-- Connection pressure vs max_connections (200):
SELECT count(*) AS conns,
       (SELECT setting::int FROM pg_settings WHERE name='max_connections') AS max
FROM pg_stat_activity;

-- Long-running / stuck transactions (lock holders):
SELECT pid, now()-xact_start AS xact_age, state, wait_event_type, query
FROM pg_stat_activity
WHERE state <> 'idle' AND now()-xact_start > interval '1 minute'
ORDER BY xact_age DESC;

-- Transaction ID wraparound headroom (must never run out):
SELECT datname, age(datfrozenxid) AS xid_age FROM pg_database ORDER BY 2 DESC;

-- Cache hit ratio (should be > 0.99 with 8GB shared_buffers):
SELECT sum(blks_hit)::float/nullif(sum(blks_hit)+sum(blks_read),0) AS cache_hit_ratio
FROM pg_stat_database;

-- Top slow statements (needs pg_stat_statements, enabled in tuned conf):
SELECT mean_exec_time, calls, query
FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;
```

| Signal | Warning | Critical |
|---|---|---|
| connections / max_connections | > 70% | > 90% |
| oldest xact age | > 5 min | > 30 min (blocks vacuum, holds locks) |
| `age(datfrozenxid)` | > 1.0 e9 | > 1.5 e9 (wraparound risk) |
| cache_hit_ratio | < 0.99 | < 0.95 |
| deadlocks (pg_stat_database.deadlocks rising) | any sustained | spikes near deadlines |

---

## 6. Backups (close the loop)

- `pgbackrest --stanza=smarttds info` — alert if newest full backup age > 26 h.
- WAL archiving: alert if `pg_stat_archiver.last_failed_time` is recent or
  `archived_count` stops increasing (broken `archive_command` → PITR gap).

```sql
SELECT archived_count, failed_count, last_archived_time, last_failed_time
FROM pg_stat_archiver;
```

- **restore-test.sh** (backup/) must PASS on its weekly schedule — alert on any
  non-zero exit. A failing drill = treat backups as untrusted.

---

## Suggested alert summary (page vs ticket)

**Page now:** no leader / split-brain, replication lag > 10 s or no sync
standby, `postgres_write` backend down, etcd no quorum, WAL archiving failing,
disk > 90%, restore drill failed.

**Ticket / Slack:** replication lag 5–10 s, PgBouncer cl_waiting, one API node
down, cache hit < 0.99, long transactions, full backup age > 26 h.
