# Báo cáo nhóm o (I08, I09, O01–O06)

Môi trường soạn và kiểm chứng: Postgres 18.6 (container `sql-practice-pg`), Docker Desktop trên WSL2, 8 CPU, 8 GB RAM cho Docker.
Kiểm định: `bash tools/verify.sh lessons/I08-* lessons/I09-* lessons/O0*` → **34 đạt · 29 tự đối chiếu · 0 lỗi** (mọi đáp án tự khớp, mọi `trap` bị bắt, mọi `alt` được nhận, số dòng trong đề khớp).

## Nội dung
| Module | Nội dung | Bài tự động | Bài manual |
|---|---|---|---|
| I08 | LATERAL, grouping sets (bổ sung README/exercises/hints/ex09 quy mô) | 8 | 1 |
| I09 | view, materialized view, function, trigger | 8 | 1 |
| O01 | security: role, privilege, RLS, injection | 6 | 1 |
| O02 | backup, PITR, kiểm thử restore | 0 | 7 |
| O03 | monitoring: pg_stat_*, locks, log chậm, auto_explain | 3 | 4 |
| O04 | connections: chi phí kết nối, max_connections, PgBouncer | 3 | 5 |
| O05 | tuning: bộ nhớ, cost planner, checkpoint | 3 | 5 |
| O06 | replication & HA: streaming, lag, failover, logical | 3 | 5 |
| **Tổng** | | **34** | **29** |

(I08–O03 do các lượt soạn trước trên nhánh `content/o`; phần O04–O06 soạn ở lượt hoàn thiện này, cùng bước giải conflict `tools/lib.sql` khi gộp với `main`.)

## Cách soạn O04–O06
- Bài cấu hình server hoặc cần nhiều instance chạy trong **container tạm** (`postgres:18` đã có sẵn trên máy), mạng Docker riêng; không đổi cấu hình `sql-practice-pg`. PgBouncer 1.26.0 cài bằng `apt` trong container tạm. Toàn bộ container/network/DB tạm đã được dọn.
- Mọi số trong các `solutions/*.md` lấy từ lần chạy thật. Chỗ **chưa đo** hoặc là suy luận được ghi rõ trong từng file ("chưa đo", "suy luận", "một lần chạy").
- Bài chấm tự động của O04–O06 dùng **dữ liệu cố định** (bảng snapshot) hoặc đọc `pg_settings`/`EXPLAIN`, nên không cần replica hay PgBouncer thật để chạy `verify.sh`.

## Điều đáng chú ý khi đo (đưa vào bài học)
- **O04:** kết nối mới cho mỗi giao dịch chậm hơn ≈ 29× (428 so với 12 283 tps); qua TCP + SCRAM, mở kết nối mất 15,3 ms. PgBouncer cứu được 300 client vào server `max_connections = 100` (9 358 tps) nhưng **chậm hơn ≈ 30%** với 4 client bền. Tái hiện cả ba bẫy transaction mode.
- **O05:** sort 600k dòng cần ≈ 73 MB trong RAM dù chỉ ghi 46 MB ra đĩa; 3 node Sort trong một truy vấn dùng 270 MB với `work_mem = 256MB`; `random_page_cost = 1,1` khiến planner chọn Index Scan chậm hơn 3–4× ở độ chọn lọc 20–50% khi dữ liệu đã nằm trong cache; `shared_buffers` 128MB→2GB nâng cache hit 64%→99% mà tps gần như không đổi; `synchronous_commit = off` cho +144% (đổi cam kết độ bền). Một lần đo cho thấy spill ra đĩa nhanh hơn in-memory sort ≈ 18% (ghi là một lần đo).
- **O06:** tái hiện read-your-writes bị vỡ, split-brain, `pg_rewind`, và hai bẫy khi rejoin (`pg_hba` cho replication, replication slot không tự sao chép); đo xung đột replay (`hot_standby_feedback` off/on); tái hiện 5 bẫy của logical replication.

## Sự cố trong lúc soạn (cần biết)
Khi thử tái hiện `too many clients already` trực tiếp trên `sql-practice-pg` bằng ≈ 100 kết nối `psql` mở dồn dập sát giới hạn 100, server tự restart một lần (`untracked child process … exited with exit code 2` → crash recovery ≈ 5 s, không OOM, không mất dữ liệu, đủ 10 database sau đó). Chưa tìm được nguyên nhân gốc. Từ đó phần tái hiện này làm trên container tạm với `max_connections = 20` (O04 ex06) và bài có cảnh báo an toàn.

## Chưa làm / hạn chế
- Chưa verify trên `shop_l` (không bài nào của nhóm này cần).
- Phép đo là một lần chạy mỗi mức (nhiễu ±10%); môi trường ảo hóa (WSL2) nên chi phí `fsync` và độ trễ mạng không đại diện cho máy chủ vật lý hay kết nối giữa hai vùng.
- Chưa đo: thời gian phục hồi sau crash theo `max_wal_size`; replication với độ trễ mạng giả lập; PgBouncer với TLS; `LISTEN/NOTIFY` qua transaction pooling (chỉ nêu theo tài liệu).
- Không bài nào dựng Patroni (chỉ khái niệm, đúng ROADMAP).
