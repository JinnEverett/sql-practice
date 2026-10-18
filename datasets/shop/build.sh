#!/usr/bin/env bash
# Sinh (lại) database shop_<scale> từ đầu.
# Dùng:  datasets/shop/build.sh <xs|s|m|l|xl|N> [tên_db]
#   xs=100  s=10k  m=1M  l=10M  xl=100M đơn hàng (orders). Có thể truyền số N tùy ý (cần kèm tên_db).
set -euo pipefail
export MSYS_NO_PATHCONV=1
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"

scale="${1:?Dùng: build.sh <xs|s|m|l|xl|N> [tên_db]}"
case "$scale" in
  xs) N=100 ;;
  s)  N=10000 ;;
  m)  N=1000000 ;;
  l)  N=10000000 ;;
  xl) N=100000000 ;;
  *[!0-9]*) echo "scale không hợp lệ: $scale" >&2; exit 1 ;;
  *)  N="$scale" ;;
esac
db="${2:-shop_$scale}"

pg() { docker exec -i sql-practice-pg psql -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }

echo "==> Tạo $db (N = $N đơn hàng)"
pg -d postgres -c "DROP DATABASE IF EXISTS $db WITH (FORCE)"
pg -d postgres -c "CREATE DATABASE $db TEMPLATE shop_template"

start=$(date +%s)
pg -d "$db" < "$here/schema.sql"
pg -d "$db" -v N="$N" < "$here/generate.sql"
echo "  constraints"
pg -d "$db" < "$here/constraints.sql" > /dev/null
pg -d "$db" < "$root/bench/bench.sql"
echo "  vacuum analyze"
pg -d "$db" -c "VACUUM (ANALYZE)"
end=$(date +%s)

echo "==> Xong $db sau $((end - start))s"
pg -d "$db" <<'SQL'
SELECT c.relname                                     AS "bảng",
       to_char(c.reltuples, 'FM999,999,999,999')     AS "số dòng (ước lượng)",
       pg_size_pretty(pg_table_size(c.oid))          AS "dữ liệu",
       pg_size_pretty(pg_indexes_size(c.oid))        AS "index"
FROM pg_class c
WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r'
ORDER BY pg_total_relation_size(c.oid) DESC;

SELECT pg_size_pretty(pg_database_size(current_database())) AS "tổng dung lượng DB";
SQL
