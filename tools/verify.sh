#!/usr/bin/env bash
# Kiểm định bộ đáp án: mỗi solutions/exNN.sql phải ĐÚNG khi chấm chính nó, mỗi exNN.trap*.sql (lời giải sai hay gặp)
# phải bị chấm SAI, mỗi exNN.alt*.sql (cách giải đúng khác) phải được chấm ĐÚNG,
# và số dòng ghi trong exercises.md phải khớp số dòng thật của đáp án.
#   bash tools/verify.sh                     # mọi bài có thư mục solutions/
#   bash tools/verify.sh lessons/I03-*       # chỉ vài bài
set -u
export MSYS_NO_PATHCONV=1
source "$(dirname "${BASH_SOURCE[0]}")/pg-runner.sh"
root=$(cd "$(dirname "$0")/.." && pwd)
if [ $# -gt 0 ]; then dirs=("$@"); else mapfile -t dirs < <(ls -d "$root"/lessons/*/solutions "$root"/designs/*/solutions 2>/dev/null | xargs -n1 dirname); fi
pass=0; fail=0; manual=0; failed=()
for d in "${dirs[@]}"; do
  d=${d%/}; [ -d "$d/solutions" ] || continue
  ex=$d/exercises.md
  for sol in "$d"/solutions/ex[0-9][0-9].sql; do
    [ -f "$sol" ] || continue
    nn=$(basename "$sol" .sql); nn=${nn#ex}
    mode=$(sed -n 's/^-- mode:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$sol" | head -1 | tr -d '\r'); mode=${mode:-query}
    tag="$(basename "$d") ex$nn"
    if [ "$mode" = manual ]; then
      # bài tự đối chiếu: phải có lời giải .md; file .sql (nếu có lệnh) phải chạy được không lỗi
      [ -f "$d/solutions/ex$nn.md" ] || { echo "❌ $tag: thiếu solutions/ex$nn.md"; fail=$((fail+1)); failed+=("$tag"); continue; }
      db=$(sed -n 's/^-- db:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$sol" | head -1 | tr -d '\r'); db=${db:-shop_s}
      if grep -qv '^\s*\(--.*\)\?$' "$sol"; then
        if ! tr -d '\r' < "$sol" | sql_pg -d "$db" -X -q -v ON_ERROR_STOP=1 > /dev/null 2> /tmp/verify_err; then
          echo "❌ $tag: demo SQL lỗi: $(grep ERROR /tmp/verify_err | head -1)"; fail=$((fail+1)); failed+=("$tag"); continue
        fi
      fi
      manual=$((manual+1)); echo "📝 $tag: manual (demo chạy được)"; continue
    fi
    out=$(bash "$root/tools/check.sh" "$d" "$nn" "$sol" 2>&1)
    if ! grep -q '✅ ĐÚNG' <<< "$out"; then echo "❌ $tag: đáp án không tự khớp"; echo "$out" | sed 's/^/     /' | head -15; fail=$((fail+1)); failed+=("$tag"); continue; fi
    msg="✅ $tag"
    bad=0
    # số dòng kỳ vọng
    exp=$(sed -n 's/^-- expect-rows:[[:space:]]*\([0-9]*\).*/\1/p' "$sol" | head -1)
    if [ "$mode" = query ]; then
      got=$(sed -n 's/^Số dòng  : bài làm \([0-9]*\).*/\1/p' <<< "$out")
      if [ -n "$exp" ] && [ "$exp" != "$got" ]; then echo "❌ $tag: expect-rows=$exp nhưng đáp án ra $got dòng"; bad=1; fi
      if [ -f "$ex" ]; then
        doc=$(awk -v h="### ex$nn" 'index($0,h)==1{f=1;next} f&&/^#/{f=0} f' "$ex" | grep -o '\*\*[0-9][0-9 ]*dòng\*\*' | head -1 | tr -dc '0-9')
        if [ -n "$doc" ] && [ "$doc" != "$got" ]; then echo "❌ $tag: exercises.md ghi $doc dòng nhưng đáp án ra $got"; bad=1; fi
        [ -z "$doc" ] && msg="$msg (⚠️ exercises.md không ghi số dòng)"
      fi
      msg="$msg · $got dòng"
    fi
    # lời giải sai phải bị bắt
    for trap in "$d"/solutions/ex$nn.trap*.sql; do
      [ -f "$trap" ] || continue
      tout=$(bash "$root/tools/check.sh" "$d" "$nn" "$trap" 2>&1)
      if grep -q '✅ ĐÚNG' <<< "$tout"; then echo "❌ $tag: $(basename "$trap") (lời giải sai) lại được chấm ĐÚNG"; bad=1
      else msg="$msg · bắt được $(basename "$trap" .sql | sed 's/.*\.//')"; fi
    done
    # lời giải đúng theo cách khác phải được chấm ĐÚNG (chống bộ chấm quá khắt khe)
    for alt in "$d"/solutions/ex$nn.alt*.sql; do
      [ -f "$alt" ] || continue
      aout=$(bash "$root/tools/check.sh" "$d" "$nn" "$alt" 2>&1)
      if grep -q '✅ ĐÚNG' <<< "$aout"; then msg="$msg · nhận $(basename "$alt" .sql | sed 's/.*\.//')"
      else echo "❌ $tag: $(basename "$alt") (cách giải đúng khác) lại bị chấm SAI"; echo "$aout" | grep -E '❌|ERROR' | head -5 | sed 's/^/     /'; bad=1; fi
    done
    if [ $bad -eq 1 ]; then fail=$((fail+1)); failed+=("$tag"); else pass=$((pass+1)); echo "$msg"; fi
  done
done
echo "-----"
echo "Tổng: $pass đạt · $manual tự đối chiếu · $fail lỗi"
[ $fail -eq 0 ] || { printf '  %s\n' "${failed[@]}"; exit 1; }
