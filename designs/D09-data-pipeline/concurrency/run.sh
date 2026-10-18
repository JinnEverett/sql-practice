#!/usr/bin/env bash
# Mất sự kiện khi poll theo id: 16 writer commit không theo thứ tự id, hai reader chạy song song trên cùng luồng.
# Cần schema.sql đã chạy trên lab.   bash designs/D09-data-pipeline/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
echo "SET search_path=d09; TRUNCATE demo_events, demo_result RESTART IDENTITY;" | sql_pg -d lab -X -q
sql_pg -d lab -X -q -v ON_ERROR_STOP=1 < "$here/reader_naive.sql" & p1=$!
sql_pg -d lab -X -q -v ON_ERROR_STOP=1 < "$here/reader_safe.sql" & p2=$!
sleep 0.5
if [ "${SQL_PG:-docker}" = local ]; then
  pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 16 -j 4 -T 8 -f "$here/writer.pgbench" lab 2>&1 | grep -E "actually processed"
else
  docker exec -i sql-practice-pg sh -c 'cat > /tmp/w.sql; pgbench -U postgres -n -c 16 -j 4 -T 8 -f /tmp/w.sql lab' < "$here/writer.pgbench" 2>&1 | grep -E "actually processed"
fi
wait $p1 $p2
echo "SET search_path=d09; SELECT (SELECT count(*) FROM demo_events) AS written, mode, seen, (SELECT count(*) FROM demo_events) - seen AS lost FROM demo_result ORDER BY mode;" | sql_pg -d lab -X
