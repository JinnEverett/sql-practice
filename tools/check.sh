#!/usr/bin/env bash
# Tự chấm 1 bài trên Postgres thật.
#   bash tools/check.sh <thư-mục-bài> <NN> [file-bài-làm]
#   vd. bash tools/check.sh lessons/I03-window-ranking 04
#       bash tools/check.sh lessons/I03-window-ranking 04 lessons/I03-window-ranking/solutions/ex04.sql   (thử đáp án)
#
# Đáp án tham chiếu nằm ở <bài>/solutions/exNN.sql. Dòng đầu file khai báo cách chấm:
#   -- db: shop_s       DB để chạy (mặc định shop_s)
#   -- mode: query      so KẾT QUẢ với đáp án (mặc định)
#   -- mode: state      chạy bài làm (DML/DDL) trong BEGIN…ROLLBACK rồi so TRẠNG THÁI bảng (solutions/exNN.state.sql)
#   -- mode: check      chạy bộ test solutions/exNN.check.sql lên bài làm (index, ràng buộc, plan, concurrency…)
#   -- mode: manual     bài trả lời bằng lời / thí nghiệm: tự đối chiếu với solutions/exNN.md
#   -- ordered          (query/state) so cả THỨ TỰ dòng
#   -- reset            chạy setup.sql của bài trước khi chấm (dữ liệu về trạng thái ban đầu)
#   -- show-output      (state) so cả output của câu lệnh (RETURNING)
# Mã thoát: 0 đúng · 1 sai/lỗi · 2 chưa có bài làm · 3 bài tự đối chiếu
set -u
export MSYS_NO_PATHCONV=1
root=$(cd "$(dirname "$0")/.." && pwd)
[ $# -ge 2 ] || { sed -n '2,18p' "$0"; exit 1; }
dir=${1%/}; [ -d "$dir" ] || dir="$root/$dir"
nn=$2
ref=$dir/solutions/ex$nn.sql
[ -f "$ref" ] || { echo "Không thấy đáp án: $ref"; exit 1; }
ans=${3:-$dir/answers/ex$nn.sql}

hdr()  { sed -n "s/^-- $1:[[:space:]]*\([^[:space:]]*\).*/\1/p" "$ref" | head -1 | tr -d '\r'; }
flag() { grep -q "^-- $1\([[:space:]]\|$\)" "$ref"; }
db=$(hdr db); db=${db:-shop_s}
mode=$(hdr mode); mode=${mode:-query}
flag ordered && ordered=1 || ordered=0
flag reset && reset=1 || reset=0
flag show-output && show=1 || show=0
setup=$dir/setup.sql

name=$(basename "$dir")
echo "== $name · ex$nn · DB $db · mode $mode"

if [ "$mode" = manual ]; then
  echo "Bài tự đối chiếu: so bài làm của bạn với $dir/solutions/ex$nn.md"
  exit 3
fi
if [ ! -f "$ans" ]; then
  [ -f "${ans%.sql}.md" ] && { echo "Bài này chấm bằng SQL, cần file $ans"; exit 2; }
  echo "Chưa có bài làm: $ans"; exit 2
fi

source "$(dirname "${BASH_SOURCE[0]}")/pg-runner.sh"
pg() { sql_pg -d "$db" -X -q -v ON_ERROR_STOP=1 "$@"; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
silent_setup() { if [ $reset -eq 1 ] && [ -f "$setup" ]; then echo '\o /dev/null'; echo '\set QUIET on'; cat "$setup"; echo; echo '\o'; fi; }
strip_cr() { tr -d '\r' < "$1"; }

# ---------------------------------------------------------------- query
if [ "$mode" = query ]; then
  run() { { silent_setup; strip_cr "$1"; echo; } | pg --csv; }
  if ! run "$ans" > "$tmp/a" 2> "$tmp/err"; then echo "Kết quả  : ❌ lỗi khi chạy bài làm"; grep -v NOTICE "$tmp/err" | head -8; exit 1; fi
  if ! run "$ref" > "$tmp/r" 2> "$tmp/rerr"; then echo "⚠️  đáp án lỗi (báo coach):"; head -5 "$tmp/rerr"; exit 1; fi
  head -1 "$tmp/a" > "$tmp/ah"; head -1 "$tmp/r" > "$tmp/rh"
  tail -n +2 "$tmp/a" > "$tmp/ab"; tail -n +2 "$tmp/r" > "$tmp/rb"
  LC_ALL=C sort "$tmp/ab" > "$tmp/as"; LC_ALL=C sort "$tmp/rb" > "$tmp/rs"
  LC_ALL=C comm -13 "$tmp/as" "$tmp/rs" > "$tmp/missing"
  LC_ALL=C comm -23 "$tmp/as" "$tmp/rs" > "$tmp/extra"
  ok=1
  if cmp -s "$tmp/ah" "$tmp/rh"; then echo "Cột      : ✅ $(cat "$tmp/ah")"
  else ok=0; echo "Cột      : ❌ bài làm: $(cat "$tmp/ah")"; echo "           kỳ vọng: $(cat "$tmp/rh")"; fi
  echo "Số dòng  : bài làm $(wc -l < "$tmp/ab") · kỳ vọng $(wc -l < "$tmp/rb")"
  m=$(wc -l < "$tmp/missing"); e=$(wc -l < "$tmp/extra")
  [ "$m" -gt 0 ] && { ok=0; echo "Thiếu    : $m dòng, ví dụ: $(head -1 "$tmp/missing")"; }
  [ "$e" -gt 0 ] && { ok=0; echo "Thừa     : $e dòng, ví dụ: $(head -1 "$tmp/extra")"; }
  if [ "$m" -eq 0 ] && [ "$e" -eq 0 ] && [ $ordered -eq 1 ]; then
    if cmp -s "$tmp/ab" "$tmp/rb"; then echo "Thứ tự   : ✅"
    else ok=0; n=$(diff <(cat -n "$tmp/ab") <(cat -n "$tmp/rb") | grep -m1 '^<' | awk '{print $2}')
         echo "Thứ tự   : ❌ đúng tập dòng nhưng sai thứ tự, lệch từ dòng $n"; fi
  fi
  [ $ok -eq 1 ] && { echo "Kết quả  : ✅ ĐÚNG"; exit 0; } || { echo "Kết quả  : ❌ SAI"; exit 1; }
fi

# ---------------------------------------------------------------- state
if [ "$mode" = state ]; then
  st=$dir/solutions/ex$nn.state.sql
  [ -f "$st" ] || { echo "Thiếu $st"; exit 1; }
  grep -q '^-- ordered' "$st" && ordered=1
  build() {
    echo '\o /dev/null'; echo '\set QUIET on'; [ -f "$setup" ] && cat "$setup"; echo; echo '\o'
    echo "BEGIN;"
    [ $show -eq 1 ] || echo '\o /dev/null'
    strip_cr "$1"; echo; echo ';'
    echo '\o'
    echo "SELECT '--- trạng thái sau khi chạy ---' AS _;"
    cat "$st"; echo
    echo "ROLLBACK;"
  }
  if ! build "$ans" | pg -A -F'|' > "$tmp/a" 2> "$tmp/err"; then echo "Kết quả  : ❌ lỗi khi chạy bài làm"; grep -v NOTICE "$tmp/err" | head -8; exit 1; fi
  if ! build "$ref" | pg -A -F'|' > "$tmp/r" 2> "$tmp/rerr"; then echo "⚠️  đáp án lỗi (báo coach):"; head -5 "$tmp/rerr"; exit 1; fi
  if [ $ordered -eq 1 ]; then A=$(cat "$tmp/a"); R=$(cat "$tmp/r"); else A=$(LC_ALL=C sort "$tmp/a"); R=$(LC_ALL=C sort "$tmp/r"); fi
  if [ "$A" = "$R" ]; then echo "Kết quả  : ✅ ĐÚNG ($(wc -l < "$tmp/r") dòng trạng thái khớp)"; exit 0; fi
  echo "Kết quả  : ❌ SAI (trạng thái bảng khác kỳ vọng)"
  diff <(echo "$A") <(echo "$R") | grep '^[<>]' | head -12 | sed 's/^</bài làm :/; s/^>/kỳ vọng :/'
  exit 1
fi

# ---------------------------------------------------------------- check
if [ "$mode" = check ]; then
  ck=$dir/solutions/ex$nn.check.sql
  [ -f "$ck" ] || { echo "Thiếu $ck"; exit 1; }
  tag='$ans_q7z$'
  {
    echo '\set QUIET on'
    cat "$root/tools/lib.sql"; echo
    silent_setup
    printf 'SELECT %s' "$tag"; strip_cr "$ans"; printf '%s AS ans \\gset\n' "$tag"
    printf '\\set ansfile %s\n' "$(basename "$ans")"
    cat "$ck"; echo
  } | pg > "$tmp/out" 2>&1
  rc=$?
  sed -n 's/.*NOTICE:  \(\(PASS\|FAIL\|INFO\): .*\)/\1/p' "$tmp/out" | sed 's/^PASS:/  ✅/; s/^FAIL:/  ❌/; s/^INFO:/  ℹ️ /'
  if [ $rc -ne 0 ]; then
    echo "Kết quả  : ❌ lỗi khi chạy:"; grep -E 'ERROR|LINE|^\s+\^' "$tmp/out" | head -6; exit 1
  fi
  if grep -q 'NOTICE:  FAIL:' "$tmp/out" || ! grep -q 'NOTICE:  PASS:' "$tmp/out"; then echo "Kết quả  : ❌ SAI"; exit 1; fi
  echo "Kết quả  : ✅ ĐÚNG"; exit 0
fi

echo "mode không hợp lệ: $mode"; exit 1
