# SmartTds — Phase 4 High-Availability Runbook

Operator guide for the production HA PostgreSQL 16 + ASP.NET Core API stack.
Everything referenced here lives in `_migration/phase4/`.

| File | Role |
|---|---|
| `docker-compose.ha.yml` | LOCAL runnable HA rehearsal (Spilo/Patroni + etcd + PgBouncer + HAProxy + 2 API) |
| `patroni/patroni-node1.yml`, `patroni-node2.yml` | Production Patroni configs (bare VMs / systemd) |
| `pgbouncer/pgbouncer.ini`, `userlist.txt.example` | Transaction pooling, per-(user,db) sizing |
| `haproxy/haproxy.cfg` | API HTTP front + Postgres RW/RO split via Patroni REST checks |
| `postgres/postgresql.tuned.conf` | 8 vCPU/32 GB tuning (+ commented 4c/8GB VPS block) |
| `backup/pgbackrest.conf` | Full+incr backups, WAL archive, S3 off-site, PITR |
| `backup/pg_basebackup_and_wal.sh` | Simple fallback backup |
| `backup/restore-test.sh` | Automated restore drill |
| `monitoring/README.md` | What to watch, exact queries, thresholds |

---

## 1. Architecture

```
                          Clients (WinForms / browser)
                                     |
                                     v  HTTPS
                    +-----------------------------------+
                    |  keepalived VIP  (floating IP)    |
                    |  HAProxy-A  /  HAProxy-B  (active- |
                    |  passive; either can serve)       |
                    +-----------------------------------+
                       |  :8080 HTTP        |  :5000 RW / :5001 RO (TCP)
                       v                    v
                +-----------+        +--------------------+
                |  api1     |        |   PgBouncer (x2)   |  transaction pooling
                |  api2     |---SQL->|  per-(user,db)     |
                | (JWT,     |        |  pools             |
                |  stateless|        +--------------------+
                +-----------+                 |
                  ^   year->DB routing        |  RW to :5000 (HAProxy)
                  |   per request             v
                  |                  +--------------------+      etcd quorum (x3)
                  |                  |  HAProxy RW/RO     |<---- leader lookup via
                  |                  |  uses Patroni REST |      Patroni REST :8008
                  |                  |  :8008 /leader     |
                  |                  +--------------------+            ^
                  |                       |          |                 |
                  |                       v          v                 |
                  |              +-----------+   +-----------+         |
                  |              | PG node1  |   | PG node2  |  Patroni manages both
                  |              | Patroni   |<=>| Patroni   |  streaming + SYNC
                  |              | LEADER    |   | SYNC STBY |  replication (RPO 0)
                  |              +-----------+   +-----------+
                  |                   |  archive_command (WAL)  |
                  |                   v                          v
                  |              +------------------------------------+
                  |              | pgBackRest repo: local + S3 off-site|
                  |              | full+diff+incr, PITR, restore drill |
                  |              +------------------------------------+
                  |
            (App picks the DB by ASSESSMENT YEAR: smarttds26/25/... + masterdbtds,
             all on the SAME cluster, so one failover covers every year DB at once.)
```

Key properties:
- **Zero data loss (RPO 0):** `synchronous_mode: true` in Patroni +
  `synchronous_commit = on`. A write is acknowledged only once the synchronous
  standby has it. (See `patroni-node1.yml`; set `synchronous_mode_strict: true`
  if you'd rather BLOCK writes than ever fall back to async.)
- **Automatic failover:** Patroni + etcd elect a new leader if the primary dies.
  HAProxy follows automatically because its RW backend only marks a node UP when
  Patroni REST `/leader` returns 200 — no HAProxy reconfig on failover.
- **Read scaling:** HAProxy `:5001` / the `*_ro` PgBouncer alias send heavy
  reports to the standby.
- **Single cluster, many DBs:** all assessment-year DBs + `masterdbtds` live
  together, so HA/backup/failover are cluster-wide and consistent.

---

## 2. How failover works

### Automatic (Patroni)
1. Leader stops heart-beating to etcd; its leader lease (`ttl: 30s`) expires.
2. Patroni on the synchronous standby sees the lease gone, confirms it is the
   most-advanced eligible member (`maximum_lag_on_failover` guard), and promotes
   itself; it grabs the leader key in etcd.
3. The optional **watchdog** fences the old node to prevent split-brain.
4. HAProxy's next health poll: old node now returns 503 on `/leader` (DOWN),
   new leader returns 200 (UP). Writes flow to the new leader within seconds.
5. The old node, when it returns, is rejoined automatically via **pg_rewind**
   (enabled by `use_pg_rewind` + `wal_log_hints=on`) as the new standby.

Expected write outage: roughly `ttl + loop_wait` (~tens of seconds). In-flight
connections drop (HAProxy `on-marked-down shutdown-sessions`); the app/Npgsql
retries and reconnects through PgBouncer.

### Manual (planned maintenance) — `patronictl`
```bash
patronictl -c /etc/patroni/patroni.yml list smarttds          # see current roles
patronictl -c /etc/patroni/patroni.yml switchover smarttds \
    --leader smarttds-pg1 --candidate smarttds-pg2            # graceful, no data loss
patronictl -c /etc/patroni/patroni.yml failover smarttds      # forced (leader already gone)
patronictl -c /etc/patroni/patroni.yml pause smarttds         # maintenance: stop auto-failover
patronictl -c /etc/patroni/patroni.yml resume smarttds        # re-enable after maintenance
patronictl -c /etc/patroni/patroni.yml restart smarttds smarttds-pg2   # rolling restart
patronictl -c /etc/patroni/patroni.yml edit-config smarttds   # change DCS params live
```
Always `switchover` (not stop the primary) for planned work — it picks a clean
moment and keeps RPO 0.

---

## 3. Adding / rebuilding the standby

New standby or replacing a dead node (Patroni clones it for you):
1. Install PostgreSQL 16 + Patroni on the new VM; identical `bin_dir`/`data_dir`.
2. Copy `patroni-node2.yml` -> `/etc/patroni/patroni.yml`; set a UNIQUE `name`
   and this node's `connect_address` (REST :8008 and PG :5432).
3. Ensure it can reach etcd and the leader; replication user/password match.
4. Leave `data_dir` EMPTY. Start Patroni:
   `systemctl start patroni`. Patroni runs `pg_basebackup`/clone from the
   leader, then begins streaming. Confirm with `patronictl list` (state running,
   becomes Sync Standby).
5. Register it in `backup/pgbackrest.conf` (`pgN-host=...`) so backups can run
   off it.

To re-add a former primary after failover: just start Patroni — `pg_rewind`
re-aligns its timeline and it rejoins as standby.

---

## 4. Deploy order (production, from scratch)

1. **etcd quorum** (3 nodes). Verify `etcdctl endpoint health` on all.
2. **PostgreSQL + Patroni node1** -> it bootstraps the cluster (initdb, writes
   DCS config). `patronictl list` shows it as Leader.
3. Provision databases & roles: `masterdbtds`, `smarttds26`, ... and the
   `smarttds_app`, `replicator`, `rewind_user`, monitoring roles. Load schema
   (reuse Phase 1 `run_pg_migration.ps1` output).
4. **Patroni node2** with empty data_dir -> auto-clones, becomes Sync Standby.
   Confirm `sync_state = sync` in `pg_stat_replication`.
5. **pgBackRest**: `stanza-create`, then `check`; take first `--type=full`
   backup; confirm WAL archiving (`pg_stat_archiver`). Schedule cron (see below).
6. **PgBouncer (x2)**: deploy `pgbouncer.ini` + real `userlist.txt` (SCRAM
   verifiers). Point upstream at HAProxy :5000.
7. **HAProxy (x2) + keepalived VIP**: deploy `haproxy.cfg`; verify RW backend
   shows exactly the leader UP and RO shows the standby UP (stats :7000).
8. **API nodes (x2)**: deploy SmartTds API; connection string -> PgBouncer
   :6432; `/health` green; confirm HAProxy `api_nodes` both UP.
9. **Monitoring**: wire exporters/queries from `monitoring/README.md`; set
   alerts. Schedule `restore-test.sh` weekly.

Backup cron (run on the standby; see pgbackrest.conf cheat-sheet):
```
0 1 * * *   pgbackrest --stanza=smarttds --type=full backup   # 7-daily retention
0 */6 * * * pgbackrest --stanza=smarttds --type=diff backup
30 * * * *  pgbackrest --stanza=smarttds --type=incr backup
0 2 * * 0   pgbackrest --stanza=smarttds --type=full backup   # weekly archival (4 weekly)
0 3 * * 0   /opt/smarttds/backup/restore-test.sh              # weekly restore drill
```

---

## 5. Local rehearsal (laptop)

```bash
cd _migration/phase4
# 1) Create .env with the CHANGE_ME passwords (see compose header).
# 2) VERIFY image tags marked "VERIFY TAG" in docker-compose.ha.yml.
# 3) (optional) docker build -t smarttds/api:local ../../SmartTdsApi  OR comment out api1/api2
docker compose -f docker-compose.ha.yml up -d
docker exec smarttds-patroni1 patronictl -c /home/postgres/postgres.yml list
# Test failover:
docker stop smarttds-patroni1          # patroni2 should be promoted
# Connect through the pool:
psql "host=localhost port=6432 user=smarttds_app dbname=smarttds26"
```

---

## 6. Deployment-day checklist

- [ ] etcd 3-node quorum healthy (`etcdctl endpoint health` all OK).
- [ ] All `CHANGE_ME` secrets replaced (Patroni, pgBackRest S3 + cipher,
      PgBouncer userlist SCRAM, HAProxy stats auth, API connection string).
- [ ] Docker image tags verified (only for the local rehearsal compose).
- [ ] `patronictl list` shows 1 Leader + 1 Sync Standby, both `running`.
- [ ] `pg_stat_replication.sync_state = sync` AND lag < 1 s at idle.
- [ ] pg_hba CIDRs tightened to the real VPC subnets (no 0.0.0.0/0).
- [ ] `data-checksums` enabled (initdb) — verified once, can't be added later.
- [ ] All DBs present: `masterdbtds` + every required `smarttdsNN`; app routing
      tested per year (X-Assessment-Year header).
- [ ] PgBouncer pools reachable; `SHOW POOLS` clean; pool sizes sum < 200.
- [ ] HAProxy stats (:7000): `postgres_write`=leader UP only, `postgres_read`=
      standby UP, `api_nodes` both UP.
- [ ] First pgBackRest full backup done; `pgbackrest info` healthy; WAL
      archiving succeeding (`pg_stat_archiver`).
- [ ] `restore-test.sh` PASSED at least once against the real repo.
- [ ] Monitoring alerts firing into the right channel; thresholds set
      (replication lag > 10 s, no leader, pool exhaustion, disk > 90%).
- [ ] Manual `patronictl switchover` rehearsed; app survived the flip.
- [ ] keepalived VIP fails over between HAProxy-A/B cleanly.
- [ ] Runbook + credentials location shared with on-call.
```
