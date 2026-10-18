#!/usr/bin/env bash
# Chấm bài DML: reset schema f08 → BEGIN → chạy bài làm → in trạng thái bảng → ROLLBACK, rồi so với bản tham chiếu.
# Dùng:  lessons/F08-dml/check.sh <NN>      vd. lessons/F08-dml/check.sh 03
# checks/exNN.ref.sql (tham chiếu) · checks/exNN.state.sql (query đọc trạng thái)
# "-- show-output" trong ref: so cả output RETURNING · "-- ordered" trong state: so cả thứ tự dòng
set -u
dir=$(cd "$(dirname "$0")" && pwd); nn=$1
ans=$dir/answers/ex$nn.sql; ref=$dir/checks/ex$nn.ref.sql; st=$dir/checks/ex$nn.state.sql
[ -f "$ans" ] || { echo "Chưa có bài làm: $ans"; exit 2; }
grep -q '^-- show-output' "$ref" && show=1 || show=0
grep -q '^-- ordered' "$st" && ordered=1 || ordered=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
exec_sql() { MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d lab -X -q -A -F'|' -v ON_ERROR_STOP=1; }
build() {  # $1 = file DML
  echo '\o /dev/null'; cat "$dir/setup.sql"; echo '\o'
  echo "BEGIN;"
  [ $show -eq 1 ] || echo '\o /dev/null'
  cat "$1"; echo; echo ';'
  echo '\o'
  cat "$st"
  echo "ROLLBACK;"
}
build "$ans" | exec_sql > "$tmp/a" 2> "$tmp/err"
if [ $? -ne 0 ]; then echo "❌ ex$nn: lỗi khi chạy"; grep -v 'NOTICE' "$tmp/err" | head; exit 1; fi
build "$ref" | exec_sql > "$tmp/r" 2>/dev/null
if [ $ordered -eq 1 ]; then A=$(cat "$tmp/a"); R=$(cat "$tmp/r"); else A=$(LC_ALL=C sort "$tmp/a"); R=$(LC_ALL=C sort "$tmp/r"); fi
echo "== ex$nn · DB lab"
if [ "$A" = "$R" ]; then echo "Kết quả  : ✅ ĐÚNG ($(wc -l < "$tmp/r") dòng đối chiếu)"; exit 0; fi
echo "Kết quả  : ❌ SAI"
diff <(echo "$A") <(echo "$R") | head -12 | sed 's/^</bài làm :/; s/^>/kỳ vọng :/'
exit 1
