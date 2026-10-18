#!/usr/bin/env bash
# Trần thông lượng của MỘT node theo số connection: pgbench select-only và TPC-B-like. Tạo DB d10_pgb (scale 50 = 5M dòng pgbench_accounts).
#   bash designs/D10-scaling-postgres/scripts/capacity.sh      (~3 phút)
set -u
source "$(dirname "${BASH_SOURCE[0]}")/../../../tools/pg-runner.sh"
run() {  # run <psql/pgbench args...>
  if [ "${SQL_PG:-docker}" = local ]; then pgbench -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" "$@"; else docker exec -i sql-practice-pg pgbench -U postgres "$@"; fi
}
echo "max_connections=$(echo 'SHOW max_connections' | sql_pg -d postgres -X -At)"
echo "SELECT 1" | sql_pg -d postgres -X -q -c "DROP DATABASE IF EXISTS d10_pgb WITH (FORCE)" -c "CREATE DATABASE d10_pgb" >/dev/null
run -i -s 50 -q d10_pgb >/dev/null 2>&1
echo "nproc=$(nproc)  shared_buffers=$(echo 'SHOW shared_buffers' | sql_pg -d postgres -X -At)  data=$(echo "SELECT pg_size_pretty(pg_database_size('d10_pgb'))" | sql_pg -d postgres -X -At)"
for c in 1 4 16 64 256; do
  printf "select-only  c=%-3s " $c; out=$(run -n -S -c $c -j $((c<4?c:4)) -T 8 d10_pgb 2>&1); grep -E "^tps" <<< "$out" | sed 's/ (without.*//' || true
  grep -qE "^tps" <<< "$out" || { echo "KHÔNG CHẠY ĐƯỢC: $(grep -m1 -E 'FATAL|error' <<< "$out")"; }
done
for c in 1 4 16 64; do
  printf "tpcb-like    c=%-3s " $c; run -n -c $c -j $((c<4?c:4)) -T 8 d10_pgb 2>&1 | grep -E "^tps" | sed 's/ (without.*//'
done
