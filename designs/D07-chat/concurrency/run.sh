#!/usr/bin/env bash
# Gửi tin đồng thời: cùng 1 hội thoại vs rải 20 000 hội thoại. Cần schema.sql + queries.sql (seed) đã chạy trên lab.
#   bash designs/D07-chat/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
for range in 1 20000; do
  echo "== range=$range"
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 50 -j 4 -T 10 -D range=$range -f "$here/send.pgbench" lab 2>&1 | grep -E "actually processed|tps|latency average|failed"
  else
    docker exec -i sql-practice-pg sh -c "cat > /tmp/p.sql; pgbench -U postgres -n -c 50 -j 4 -T 10 -D range=$range -f /tmp/p.sql lab" < "$here/send.pgbench" 2>&1 | grep -E "actually processed|tps|latency average|failed"
  fi
done
echo "SET search_path=d07;
SELECT count(*) AS conversations_with_seq_gap_or_dup FROM (SELECT conversation_id FROM messages GROUP BY 1 HAVING count(*) <> max(seq) OR min(seq) <> 1) x;
SELECT count(*) AS last_seq_mismatch FROM conversations c JOIN (SELECT conversation_id, max(seq) mx FROM messages GROUP BY 1) m ON m.conversation_id = c.id WHERE c.last_seq <> m.mx;" | sql_pg -d lab -X
