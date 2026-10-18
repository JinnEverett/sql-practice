#!/usr/bin/env bash
# Hot row vs counter chia mảnh: 50 client, 10 giây, mỗi giao dịch có thêm pg_sleep(0.002) để mô phỏng việc app giữ giao dịch mở.
#   bash designs/D06-social-feed/concurrency/run.sh   (cần schema.sql đã chạy trên lab)
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
echo "SET search_path=d06; TRUNCATE demo_hot, demo_shards; INSERT INTO demo_hot VALUES (1, 0); INSERT INTO demo_shards SELECT 1, s, 0 FROM generate_series(0,15) s;" | sql_pg -d lab -X -q
for mode in hot sharded; do
  echo "== $mode"
  # BEGIN; UPDATE; pg_sleep; COMMIT: giữ row lock 2ms như một giao dịch thật có thêm việc khác
  { echo "BEGIN;"; grep -v '^--' "$here/$mode.pgbench"; echo "SELECT pg_sleep(0.002);"; echo "COMMIT;"; } > /tmp/d06_$mode.sql
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 50 -j 4 -T 10 -f /tmp/d06_$mode.sql lab 2>&1 | grep -E "actually processed|tps|latency average"
  else
    docker exec -i sql-practice-pg sh -c 'cat > /tmp/p.sql; pgbench -U postgres -n -c 50 -j 4 -T 10 -f /tmp/p.sql lab' < /tmp/d06_$mode.sql 2>&1 | grep -E "actually processed|tps|latency average"
  fi
done
echo "SET search_path=d06; SELECT (SELECT n FROM demo_hot) AS hot_total, (SELECT sum(n) FROM demo_shards) AS sharded_total;" | sql_pg -d lab -X
