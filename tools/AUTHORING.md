# Quy ước soạn bài tự học (dành cho coach / người soạn)

Mỗi module trong `lessons/<ID>-<slug>/`:

| File | Nội dung |
|---|---|
| `README.md` | Lý thuyết cô đọng (≤ 10' đọc): mục tiêu, khái niệm + ví dụ chạy được, bẫy, phần "Đo bằng gì" (Tier P/O) |
| `setup.sql` | (nếu cần) tạo schema `lab.<id>` + seed cố định, idempotent (`DROP SCHEMA IF EXISTS … CASCADE`) |
| `exercises.md` | Đề: DB chạy, cột, thứ tự, **`**N dòng**`** (verify.sh đối chiếu con số này), dòng đầu. 🟢/🟡/🔴 + 📏 câu hỏi quy mô |
| `hints.md` | H1/H2/H3 cho từng bài trong `<details>` |
| `solutions/exNN.sql` | Đáp án + header chấm + comment `-- Giải thích:` / `-- Bẫy:` |
| `solutions/exNN.state.sql` | (mode state) query đọc trạng thái bảng sau khi chạy |
| `solutions/exNN.check.sql` | (mode check) bộ test; bài làm có trong biến psql `:ans` (raw) và `:'ans'` (literal) |
| `solutions/exNN.trapK.sql` | Lời giải SAI hay gặp: verify.sh yêu cầu nó bị chấm SAI |
| `solutions/exNN.md` | (mode manual) lời giải bằng lời + số đo thật |
| `answers/` | Người học viết bài |

Header của `solutions/exNN.sql`: `-- db:` · `-- mode: query|state|check|manual` · `-- ordered` · `-- reset` · `-- show-output` · `-- expect-rows: N`.

Hàm test trong `tools/lib.sql`: `pg_temp.ck(ok, msg)`, `plan(q)`, `has_node(p, node, rel)`, `uses_index(p, idx)`, `buffers(p)`, `exec_ms(p)`, `temp_written(p)`, `same(q1, q2)`, `fails(q, sqlstate)`, `ok(q)`, `val(q)`, `clean(q)`.

Bài "tối ưu" (mode check): bài làm gồm lệnh DDL (CREATE INDEX…), sau đó dòng `-- query`, rồi câu SELECT. check.sql tách bằng
`split_part(:'ans', '-- query', 1)` / `split_part(:'ans', '-- query', 2)`, chạy DDL trong `BEGIN … ROLLBACK`.

Kiểm định: `bash tools/verify.sh [lessons/<ID>-*]`. Mọi đáp án phải tự khớp, mọi trap phải bị bắt, số dòng trong đề phải khớp.
