#!/usr/bin/env bash
# 20 client x 200 chuyển tiền chéo giữa 10 tài khoản. Cần schema.sql + queries.sql (seed) đã chạy trên lab.
#   bash designs/D04-banking-ledger/concurrency/run.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
here=$(cd "$(dirname "$0")" && pwd)
for mode in safe naive; do
  echo "== $mode"
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 20 -j 4 -t 200 --failures-detailed -f "$here/$mode.pgbench" lab 2>&1 | grep -E "actually processed|failed transactions|deadlock failures"
  else
    docker exec -i sql-practice-pg sh -c 'cat > /tmp/p.sql; pgbench -U postgres -n -c 20 -j 4 -t 200 --failures-detailed -f /tmp/p.sql lab' < "$here/$mode.pgbench" 2>&1 | grep -E "actually processed|failed transactions|deadlock failures"
  fi
done
echo "SET search_path=d04;
SELECT (SELECT sum(balance) FROM account_balances) AS total_balance,
       (SELECT count(*) FROM (SELECT txn_id FROM entries GROUP BY txn_id HAVING sum(amount) <> 0) x) AS unbalanced_txns,
       (SELECT count(*) FROM account_balances b JOIN (SELECT account_id, sum(amount) s FROM entries GROUP BY 1) e USING (account_id) WHERE b.balance <> e.s) AS drift;" | sql_pg -d lab -X
