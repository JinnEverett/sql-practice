#!/usr/bin/env bash
# Streaming replica trong Docker (2 container tạm trên mạng d10net): đo lag dưới tải ghi, và "read-your-writes" async vs remote_apply.
#   bash designs/D10-scaling-postgres/scripts/replica_demo.sh      (~2 phút, tự dọn)
set -eu
cleanup() { docker rm -f d10-pri d10-rep >/dev/null 2>&1 || true; docker network rm d10net >/dev/null 2>&1 || true; }
cleanup; trap cleanup EXIT
docker network create d10net >/dev/null
docker run -d --name d10-pri --network d10net -e POSTGRES_PASSWORD=postgres postgres:18 -c shared_buffers=256MB -c max_wal_size=2GB >/dev/null
until docker exec d10-pri pg_isready -U postgres -q; do sleep 1; done; sleep 2
docker exec d10-pri bash -c 'echo "host replication all all scram-sha-256" >> "$PGDATA/pg_hba.conf"'
docker exec d10-pri psql -U postgres -Xqc "SELECT pg_reload_conf()" >/dev/null
# replica: base backup rồi chạy ở chế độ standby (-R tạo standby.signal + primary_conninfo)
docker run -d --name d10-rep --network d10net --user postgres --entrypoint bash -e PGPASSWORD=postgres postgres:18 -c \
  'pg_basebackup -h d10-pri -U postgres -D /var/lib/postgresql/18/docker -R -X stream -P >/dev/null 2>&1 && chmod 700 /var/lib/postgresql/18/docker && exec postgres -D /var/lib/postgresql/18/docker -c hot_standby=on' >/dev/null
until docker exec d10-rep pg_isready -U postgres -q 2>/dev/null; do sleep 1; done
P() { docker exec -i d10-pri psql -U postgres -X -v ON_ERROR_STOP=1 "$@"; }
echo "== replica đã kết nối?"; P -Atc "SELECT application_name, state, sync_state FROM pg_stat_replication"
echo "replica in_recovery = $(docker exec d10-rep psql -U postgres -Atc 'SELECT pg_is_in_recovery()')"

echo; echo "== 1. Lag dưới tải ghi (pgbench TPC-B, 16 client, 12 giây, scale 20)"
docker exec d10-pri pgbench -U postgres -i -s 20 -q postgres >/dev/null 2>&1; sleep 3
( docker exec d10-pri pgbench -U postgres -n -c 16 -j 4 -T 12 postgres 2>&1 | grep -E "^tps" | sed 's/ (without.*//; s/^/primary /' ) &
pb=$!
for i in $(seq 1 12); do
  P -Atc "SELECT round(extract(epoch FROM coalesce(replay_lag, interval '0'))*1000) AS replay_lag_ms, pg_wal_lsn_diff(sent_lsn, replay_lsn)::bigint AS bytes_behind FROM pg_stat_replication"; sleep 1
done | awk -F'|' '{ if ($1+0 > m) m=$1+0; if ($2+0 > b) b=$2+0; s+=$1; n++ } END { printf "replay_lag_ms: max=%d avg=%.0f ; bytes_behind max=%d (%d mẫu)\n", m, s/n, b, n }'
wait $pb

echo; echo "== 2. Read-your-writes: ghi trên primary, COMMIT, đọc NGAY trên replica (postgres_fdw), 2000 lần"
P -q <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DROP SERVER IF EXISTS rep CASCADE;
CREATE SERVER rep FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'd10-rep', port '5432', dbname 'postgres', fetch_size '10');
CREATE USER MAPPING FOR postgres SERVER rep OPTIONS (user 'postgres', password 'postgres');
DROP TABLE IF EXISTS rw CASCADE;
CREATE TABLE rw (id bigint PRIMARY KEY, v text);
CREATE FOREIGN TABLE rw_on_replica (id bigint, v text) SERVER rep OPTIONS (table_name 'rw');
CREATE TABLE rw_result (mode text, stale int, n int, ms numeric);
SQL
sleep 2
run_rw() {  # run_rw <label> <n> <id_offset> <sleep_seconds_before_read>
P -q -c "DO \$\$ DECLARE i int; found bigint; stale int := 0; t0 timestamptz := clock_timestamp(); BEGIN
  FOR i IN 1..$2 LOOP
    INSERT INTO rw VALUES (extract(epoch FROM clock_timestamp())::bigint * 100000 + i + $3, 'x'); COMMIT;
    PERFORM pg_sleep($4);
    SELECT count(*) INTO found FROM rw_on_replica WHERE id = (SELECT max(id) FROM rw);
    IF found = 0 THEN stale := stale + 1; END IF;
    COMMIT;
  END LOOP;
  INSERT INTO rw_result VALUES ('$1', stale, $2, round(extract(epoch FROM clock_timestamp() - t0) * 1000 / $2, 3));
END \$\$"
}
run_rw "async, đọc ngay" 2000 0 0
run_rw "async, chờ 20ms rồi đọc" 500 500000 0.02
P -q -c "ALTER SYSTEM SET synchronous_standby_names = '\"walreceiver\"'" -c "ALTER SYSTEM SET synchronous_commit = remote_apply" -c "SELECT pg_reload_conf()" >/dev/null
sleep 2
echo "synchronous_commit=$(P -Atc 'SHOW synchronous_commit')  sync_state=$(P -Atc 'SELECT sync_state FROM pg_stat_replication')"
run_rw "remote_apply, đọc ngay" 2000 1000000 0
P -c "SELECT mode, stale AS stale_reads, n, round(100.0*stale/n,1) AS stale_pct, ms AS avg_ms_per_write_plus_read FROM rw_result ORDER BY mode"
