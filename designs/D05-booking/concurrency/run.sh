#!/usr/bin/env bash
# 50 client tranh cùng khung giờ trong 10 giây. Cần schema.sql đã chạy trên lab.
#   bash designs/D05-booking/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
echo "SET search_path=d05; DELETE FROM bookings WHERE lower(period) >= '2030-01-01'; TRUNCATE naive_bookings;" | sql_pg -d lab -X -q
for mode in safe naive; do
  echo "== $mode"
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 50 -j 4 -T 10 -f "$here/$mode.pgbench" lab 2>&1 | grep -E "actually processed|failed transactions"
  else
    docker exec -i sql-practice-pg sh -c 'cat > /tmp/p.sql; pgbench -U postgres -n -c 50 -j 4 -T 10 -f /tmp/p.sql lab' < "$here/$mode.pgbench" 2>&1 | grep -E "actually processed|failed transactions"
  fi
done
sql_pg -d lab -X <<'SQL'
SET search_path = d05;
SELECT 'safe' AS mode, count(*) AS rows_booked, count(DISTINCT lower(period)) AS distinct_slots,
       count(*) - count(DISTINCT lower(period)) AS double_bookings
FROM bookings WHERE lower(period) >= '2030-01-01'
UNION ALL
SELECT 'naive', count(*), count(DISTINCT lower(period)), count(*) - count(DISTINCT lower(period)) FROM naive_bookings;
SQL
