#!/usr/bin/env bash
# Kiểm định Tier D: mỗi designs/<ID>-*/ phải có đủ 6 file, schema.sql + queries.sql chạy không lỗi trên DB `lab`
# (queries.sql tự seed và tự ASSERT bằng DO block, nên chạy xanh nghĩa là các khẳng định trong REFERENCE đúng).
#   bash tools/verify-designs.sh                 # mọi thiết kế
#   bash tools/verify-designs.sh designs/D03-*   # chỉ vài bài
set -u
export MSYS_NO_PATHCONV=1
source "$(dirname "${BASH_SOURCE[0]}")/pg-runner.sh"
root=$(cd "$(dirname "$0")/.." && pwd)
if [ $# -gt 0 ]; then dirs=("$@"); else mapfile -t dirs < <(ls -d "$root"/designs/*/); fi
ok=0; bad=0
for d in "${dirs[@]}"; do
  d=${d%/}; tag=$(basename "$d"); miss=""
  for f in BRIEF INTERVIEWER REFERENCE RUBRIC; do [ -s "$d/$f.md" ] || miss="$miss $f.md"; done
  for f in schema queries; do [ -s "$d/$f.sql" ] || miss="$miss $f.sql"; done
  if [ -n "$miss" ]; then echo "❌ $tag: thiếu$miss"; bad=$((bad+1)); continue; fi
  for f in schema queries; do
    if ! tr -d '\r' < "$d/$f.sql" | sql_pg -d lab -X -q -v ON_ERROR_STOP=1 > /tmp/vd_out 2> /tmp/vd_err; then
      echo "❌ $tag: $f.sql lỗi: $(grep -m1 -E 'ERROR|FATAL' /tmp/vd_err)"; bad=$((bad+1)); continue 2
    fi
  done
  echo "✅ $tag"; ok=$((ok+1))
done
echo "--- $ok xanh, $bad lỗi"
[ "$bad" -eq 0 ]
