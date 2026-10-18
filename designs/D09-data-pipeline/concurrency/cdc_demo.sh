#!/usr/bin/env bash
# CDC bằng logical decoding: cần wal_level=logical (container chính để replica) => dựng container tạm d09-cdc trên cổng 5440, chạy xong tự xóa.
#   bash designs/D09-data-pipeline/concurrency/cdc_demo.sh
set -eu
docker rm -f d09-cdc >/dev/null 2>&1 || true
docker run -d --name d09-cdc -e POSTGRES_PASSWORD=postgres -e POSTGRES_HOST_AUTH_METHOD=trust postgres:18 -c wal_level=logical -c max_slot_wal_keep_size=-1 >/dev/null
trap 'docker rm -f d09-cdc >/dev/null 2>&1' EXIT
until docker exec d09-cdc pg_isready -U postgres -q; do sleep 1; done; sleep 2
psql_() { docker exec -i d09-cdc psql -U postgres -X -v ON_ERROR_STOP=1 "$@"; }
psql_ <<'SQL'
SHOW wal_level;
CREATE TABLE outbox_demo (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, event_type text, payload jsonb);
SELECT pg_create_logical_replication_slot('s1', 'test_decoding');
INSERT INTO outbox_demo (event_type, payload) VALUES ('OrderPlaced', '{"order_id": 1}'), ('OrderPlaced', '{"order_id": 2}');
UPDATE outbox_demo SET payload = payload || '{"x": 1}' WHERE id = 1;
-- peek: đọc mà KHÔNG xác nhận (consumer chưa ack)
SELECT lsn, xid, left(data, 90) AS change FROM pg_logical_slot_peek_changes('s1', NULL, NULL) ORDER BY lsn;
SQL
echo "== Hiểm họa: slot không được tiêu thụ giữ WAL mãi mãi"
psql_ <<'SQL'
CREATE TABLE filler (id bigint, pad text);
CHECKPOINT;
SELECT pg_size_pretty(sum(size)) AS wal_dir_before FROM pg_ls_waldir();
INSERT INTO filler SELECT g, repeat('x', 200) FROM generate_series(1, 1500000) g;    -- ~ 400MB WAL
CHECKPOINT;
SELECT slot_name, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS wal_retained_by_slot FROM pg_replication_slots;
SELECT pg_size_pretty(sum(size)) AS wal_dir_with_idle_slot FROM pg_ls_waldir();
SELECT pg_drop_replication_slot('s1');
CHECKPOINT;
SELECT pg_size_pretty(sum(size)) AS wal_dir_after_drop FROM pg_ls_waldir();
SQL
