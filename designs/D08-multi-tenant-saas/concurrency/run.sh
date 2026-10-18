#!/usr/bin/env bash
# Noisy neighbor: 8 client tenant nhỏ chạy một mình vs cùng lúc với 4 client báo cáo của cá voi. Rồi đo xóa tenant.
# Cần schema.sql + queries.sql đã chạy trên lab. Chạy:  bash designs/D08-multi-tenant-saas/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
sql_pg -d lab -X -q -v ON_ERROR_STOP=1 < "$here/prep_whales.sql"
pb() {  # pb <file> <clients> <label>
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c "$2" -j 2 -T 10 -f "$here/$1" lab 2>&1 | grep -E "tps|latency average" | sed "s/^/[$3] /"
  else
    docker exec -i sql-practice-pg sh -c "cat > /tmp/$1; pgbench -U postgres -n -c $2 -j 2 -T 10 -f /tmp/$1 lab" < "$here/$1" 2>&1 | grep -E "tps|latency average" | sed "s/^/[$3] /"
  fi
}
echo "== tenant nhỏ chạy một mình"; pb light.pgbench 8 light-alone
echo "== tenant nhỏ + 4 client báo cáo cá voi"
pb heavy.pgbench 4 whale > /tmp/d08_whale.out & pw=$!
pb light.pgbench 8 light-with-whale
wait $pw; cat /tmp/d08_whale.out
echo "== xóa tenant 400k dòng"
sql_pg -d lab -X -v ON_ERROR_STOP=1 < "$here/delete_tenant.sql" 2>&1 | grep -E "rows_before|Time|^ +[0-9]+$"
