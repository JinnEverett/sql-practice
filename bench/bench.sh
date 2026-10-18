#!/usr/bin/env bash
# Chạy 1 câu lệnh SQL trên nhiều mức quy mô (shop_xs, shop_s, ...) và xuất bảng so sánh markdown.
#
# Dùng:  bench/bench.sh <query.sql> [tùy chọn]
#   --scales xs,s,m,l   các mức cần đo (mặc định: xs,s,m)
#   --runs 3            số lần chạy mỗi mức, lấy median (mặc định: 3)
#   --cold              restart Postgres trước mỗi mức để đo khi cache còn lạnh (ép runs=1)
#   --set key=value     đặt tham số phiên trước khi đo, lặp lại được (vd: --set work_mem=64MB)
#   --name tên          tên file kết quả (mặc định: tên file query)
#
# - File query chỉ chứa MỘT câu lệnh (SELECT/INSERT/UPDATE/DELETE/MERGE). Comment "--" thoải mái.
# - Mọi thay đổi dữ liệu đều bị rollback, chạy DML an toàn.
# - Kết quả in ra màn hình và lưu vào bench/results/<ngày>-<tên>.md
set -euo pipefail
export MSYS_NO_PATHCONV=1
here="$(cd "$(dirname "$0")" && pwd)"

file=""; scales="xs,s,m"; runs=3; cold=0; name=""; sets=()
while [ $# -gt 0 ]; do
  case "$1" in
    --scales) scales="$2"; shift 2 ;;
    --runs)   runs="$2"; shift 2 ;;
    --cold)   cold=1; shift ;;
    --set)    sets+=("$2"); shift 2 ;;
    --name)   name="$2"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    -*) echo "Tùy chọn không hợp lệ: $1" >&2; exit 1 ;;
    *)  file="$1"; shift ;;
  esac
done
[ -f "$file" ] || { echo "Không thấy file query: '$file'. Xem: bench/bench.sh --help" >&2; exit 1; }
[ -n "$name" ] || name="$(basename "$file" .sql)"
[ "$cold" -eq 1 ] && runs=1

source "$here/../tools/pg-runner.sh"
pg() { sql_pg -X -q -v ON_ERROR_STOP=1 "$@"; }
wait_ready() { until docker exec sql-practice-pg pg_isready -U postgres -q 2>/dev/null; do sleep 1; done; }

set_sql=""
settings_label="mặc định"
if [ ${#sets[@]} -gt 0 ]; then
  settings_label=""
  for kv in "${sets[@]}"; do
    set_sql+="SET ${kv%%=*} = '${kv#*=}';"$'\n'
    settings_label+="${kv} "
  done
fi

header="| scale | N (orders) | exec ms median (min–max) | plan | rows | shared hit / read | temp MB |"
divider="|---|---|---|---|---|---|---|"
rows=()

IFS=',' read -ra scale_list <<< "$scales"
for sc in "${scale_list[@]}"; do
  db="shop_$sc"
  if [ -z "$(pg -d postgres -tA -c "SELECT 1 FROM pg_database WHERE datname = '$db'")" ]; then
    rows+=("| $sc | — | chưa sinh DB, chạy: datasets/shop/build.sh ${sc} | | | | |")
    continue
  fi
  if [ "$cold" -eq 1 ]; then
    docker restart sql-practice-pg > /dev/null
    wait_ready
  fi
  pg -d "$db" < "$here/bench.sql" > /dev/null

  line=$(
    {
      printf '%s' "$set_sql"
      printf "SELECT format('| %%s | %%s | %%s (%%s–%%s) | %%s | %%s | %%s / %%s | %%s |',\n"
      printf "  '%s', (SELECT to_char(reltuples, 'FM999,999,999,999') FROM pg_class WHERE oid = 'public.orders'::regclass),\n" "$sc"
      printf "  exec_ms, exec_min, exec_max, nodes, out_rows, shared_hit, shared_read, temp_mb)\n"
      printf 'FROM bench.run($bench_q$\n'
      cat "$file"
      printf '\n$bench_q$, %s);\n' "$runs"
    } | pg -d "$db" -tA
  )
  rows+=("$line")
  echo "  ✓ $sc" >&2
done

mkdir -p "$here/results"
out="$here/results/$(date +%F)-$name.md"
[ -e "$out" ] && out="$here/results/$(date +%F-%H%M%S)-$name.md"

{
  echo "# Bench: $name"
  echo
  echo "- Ngày: $(date '+%F %T')"
  echo "- Query: \`$file\`"
  echo "- Runs mỗi mức: $runs$([ "$cold" -eq 1 ] && echo ' (cold: restart Postgres trước mỗi mức; cache của OS/WSL2 vẫn còn)')"
  echo "- Tham số phiên: $settings_label"
  echo
  echo '```sql'
  cat "$file"
  echo
  echo '```'
  echo
  echo "$header"
  echo "$divider"
  printf '%s\n' "${rows[@]}"
} > "$out"

echo
echo "$header"
echo "$divider"
printf '%s\n' "${rows[@]}"
echo
echo "→ Đã lưu: bench/results/$(basename "$out")"
