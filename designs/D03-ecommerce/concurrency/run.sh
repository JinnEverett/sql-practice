#!/usr/bin/env bash
# Oversell: 50 client x 40 giao dịch tranh 100 món hàng. Cần schema.sql đã chạy trên DB lab.
#   bash designs/D03-ecommerce/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
for mode in naive safe; do
  echo "SET search_path=d03; TRUNCATE demo_stock, demo_sales; INSERT INTO demo_stock VALUES (1, 100);" | sql_pg -d lab -X -q
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 50 -j 4 -t 40 -f "$here/$mode.pgbench" lab 2>&1 | grep -E "transactions actually|failed"
  else
    docker exec -i sql-practice-pg sh -c 'cat > /tmp/p.sql; pgbench -U postgres -n -c 50 -j 4 -t 40 -f /tmp/p.sql lab' < "$here/$mode.pgbench" 2>&1 | grep -E "transactions actually|failed"
  fi
  echo "== $mode: tồn đầu 100"
  echo "SET search_path=d03; SELECT (SELECT count(*) FROM demo_sales) AS sold, (SELECT on_hand FROM demo_stock) AS on_hand_left;" | sql_pg -d lab -X
done
