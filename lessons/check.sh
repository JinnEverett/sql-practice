#!/usr/bin/env bash
# Chấm 1 bài: chạy answers/exNN.sql và checks/exNN.sql trên Postgres, so kết quả.
# Dùng:  lessons/check.sh <thư-mục-bài> <NN>      vd. lessons/check.sh lessons/F01-select-basics 01
# File check có thể khai báo:  "-- db: shop_s"  (DB chạy)  và  "-- ordered"  (kiểm tra cả thứ tự).
set -u
dir=${1%/}; nn=$2
ans=$dir/answers/ex$nn.sql; ref=$dir/checks/ex$nn.sql
[ -f "$ans" ] || { echo "Chưa có bài làm: $ans"; exit 2; }
db=$(sed -n 's/^-- db:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$ref" | head -1); db=${db:-shop_s}
grep -q '^-- ordered' "$ref" && ordered=1 || ordered=0

run() { MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d "$db" -X -q --csv -v ON_ERROR_STOP=1 < "$1"; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if ! run "$ans" > "$tmp/a" 2> "$tmp/err"; then echo "❌ ex$nn: lỗi khi chạy trên $db"; cat "$tmp/err"; exit 1; fi
run "$ref" > "$tmp/r" 2>/dev/null

head -1 "$tmp/a" > "$tmp/ah"; head -1 "$tmp/r" > "$tmp/rh"
tail -n +2 "$tmp/a" > "$tmp/ab"; tail -n +2 "$tmp/r" > "$tmp/rb"
LC_ALL=C sort "$tmp/ab" > "$tmp/as"; LC_ALL=C sort "$tmp/rb" > "$tmp/rs"
LC_ALL=C comm -13 "$tmp/as" "$tmp/rs" > "$tmp/missing"   # có trong kỳ vọng, thiếu trong bài
LC_ALL=C comm -23 "$tmp/as" "$tmp/rs" > "$tmp/extra"     # bài có, kỳ vọng không có

ok=1
echo "== ex$nn · DB $db"
if cmp -s "$tmp/ah" "$tmp/rh"; then echo "Cột      : ✅ $(cat "$tmp/ah")"
else ok=0; echo "Cột      : ❌ bài làm: $(cat "$tmp/ah")"; echo "           kỳ vọng: $(cat "$tmp/rh")"; fi
echo "Số dòng  : bài làm $(wc -l < "$tmp/ab") · kỳ vọng $(wc -l < "$tmp/rb")"
m=$(wc -l < "$tmp/missing"); e=$(wc -l < "$tmp/extra")
if [ "$m" -gt 0 ]; then ok=0; echo "Thiếu    : $m dòng, ví dụ: $(head -1 "$tmp/missing")"; fi
if [ "$e" -gt 0 ]; then ok=0; echo "Thừa     : $e dòng, ví dụ: $(head -1 "$tmp/extra")"; fi
if [ "$m" -eq 0 ] && [ "$e" -eq 0 ] && [ "$ordered" -eq 1 ]; then
  if cmp -s "$tmp/ab" "$tmp/rb"; then echo "Thứ tự   : ✅"
  else ok=0; n=$(diff <(cat -n "$tmp/ab") <(cat -n "$tmp/rb") | grep -m1 '^<' | awk '{print $2}')
       echo "Thứ tự   : ❌ đúng tập dòng nhưng sai thứ tự, lệch từ dòng $n"; fi
fi
[ $ok -eq 1 ] && echo "Kết quả  : ✅ ĐÚNG" || echo "Kết quả  : ❌ SAI"
