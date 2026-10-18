#!/usr/bin/env bash
# So 3 kiểu truy vấn: bảng thường (1 node), tra theo khóa shard (1 shard qua FDW), tra theo cột khác (hỏi cả 2 shard).
# Cần schema.sql + queries.sql đã chạy.   bash designs/D10-scaling-postgres/scripts/shard_bench.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
echo "SET search_path=d10; DROP TABLE IF EXISTS users_plain; CREATE TABLE users_plain AS SELECT * FROM users; ALTER TABLE users_plain ADD PRIMARY KEY (user_id); CREATE INDEX ON users_plain (handle); ANALYZE users_plain;" | sql_pg -d lab -X -q
tmp=$(mktemp -d)
cat > $tmp/plain.sql <<'SQL'
\set id random(1, 200000)
SELECT balance FROM d10.users_plain WHERE user_id = :id;
SQL
cat > $tmp/key.sql <<'SQL'
\set id random(1, 200000)
SELECT balance FROM d10.users WHERE user_id = :id;
SQL
cat > $tmp/nokey.sql <<'SQL'
\set id random(1, 200000)
SELECT balance FROM d10.users WHERE handle = 'u' || :id;
SQL
for f in plain key nokey; do
  printf "%-6s " $f
  if [ "${SQL_PG:-docker}" = local ]; then
    pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -n -c 4 -j 4 -T 8 -f $tmp/$f.sql lab 2>&1 | grep -E "^tps|latency average" | tr '\n' ' ' | sed 's/ (without[^)]*)//'
  else
    docker exec -i sql-practice-pg sh -c "cat > /tmp/b.sql; pgbench -U postgres -n -c 4 -j 4 -T 8 -f /tmp/b.sql lab" < $tmp/$f.sql 2>&1 | grep -E "^tps|latency average" | tr '\n' ' ' | sed 's/ (without[^)]*)//'
  fi
  echo
done
rm -rf $tmp
