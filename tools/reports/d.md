# Báo cáo nhóm `d` · D01–D10 (`designs/`)

Branch `content/d`. Môi trường verify: **Postgres 18.6 trong Docker** (`postgres:18`, dựng bằng `env/docker-compose.yml`, máy cloud 4 vCPU), đúng phiên bản của người học. Mọi tính năng 18 dùng trong bài đã chạy thật (xem mục "Tính năng 18").

## Kết quả

| Module | Thư mục | Trạng thái | Ghi chú |
|---|---|---|---|
| D01 | `designs/D01-methodology` | 🧪 | ví dụ vote bài đăng áp dụng khung 7 bước |
| D02 | `designs/D02-url-shortener` | 🧪 | sinh code song ánh, click partition, rollup idempotent |
| D03 | `designs/D03-ecommerce` | 🧪 | oversell, state machine, idempotency; có pgbench |
| D04 | `designs/D04-banking-ledger` | 🧪 | double-entry, constraint trigger deferred, đối soát; có pgbench deadlock |
| D05 | `designs/D05-booking` | 🧪 | EXCLUDE gist, hold hết hạn, ghế; có pgbench |
| D06 | `designs/D06-social-feed` | 🧪 | fan-out hybrid, counter chia mảnh; có pgbench |
| D07 | `designs/D07-chat` | 🧪 | seq theo hội thoại, unread watermark; có pgbench |
| D08 | `designs/D08-multi-tenant-saas` | 🧪 | RLS, noisy neighbor, partition tenant; có pgbench |
| D09 | `designs/D09-data-pipeline` | 🧪 | outbox, consumer idempotent, rollup; mất sự kiện + CDC có đo |
| D10 | `designs/D10-scaling-postgres` | 🧪 | trần node, partition, shard bằng FDW, replica thật |

🧪 nghĩa là: đủ 6 file (`BRIEF`, `INTERVIEWER`, `REFERENCE`, `RUBRIC`, `schema.sql`, `queries.sql`) và `bash tools/verify-designs.sh` xanh cho cả 10 thiết kế. `queries.sql` tự seed và tự `ASSERT` bằng khối `DO`, nên xanh nghĩa là các khẳng định hành vi trong REFERENCE (idempotent, chặn chồng chéo, fail closed, …) đúng trên Postgres 18.6.
**Không** phải "verify.sh xanh": `tools/verify.sh` chỉ chấm `solutions/exNN.sql` nên không áp dụng cho Tier D (Tier D không có bài tự động chấm; người học trình bày thiết kế, interviewer chấm theo RUBRIC).

## Thay đổi ở `tools/`
- **Thêm** `tools/verify-designs.sh` (file mới, không đụng gì cũ): kiểm đủ 6 file, chạy `schema.sql` rồi `queries.sql` trên DB `lab` với `ON_ERROR_STOP`. Dùng `pg-runner.sh` nên chạy cả `SQL_PG=docker` và `local`.
- Không sửa `lib.sql`, `check.sh`, `verify.sh`, `pg-runner.sh`. Không sửa `ROADMAP.md`, `progress/`, `drills/`.
- `tools/CONTENT_PLAN.md`: cập nhật dòng D.

## Cấu trúc mỗi thiết kế
`BRIEF.md` (đề 2–3 câu mơ hồ, cách làm) · `INTERVIEWER.md` (⚠️ spoiler: bảng thông tin chỉ đưa khi được hỏi, yêu cầu ngầm, câu hỏi phản biện theo 7 bước, dấu hiệu đỏ) · `REFERENCE.md` (⚠️ spoiler: thiết kế 7 bước, mermaid, số đo, trade-off) · `RUBRIC.md` (6 tiêu chí × mức 1–2/3–4/5, ✅ khi ≥ 22/30, điểm trừ nặng) · `schema.sql` · `queries.sql`.
Thêm tùy module: `concurrency/` (D03–D09, script pgbench/psql tái hiện race, kèm `run.sh`) và `scripts/` (D10). Các file này chạy tay, không nằm trong `verify-designs.sh`.
**Lưu ý với `/sql-design`:** SKILL ghi `DESIGN.md`/`review.md` là sản phẩm của người học và Claude; chúng không được tạo sẵn ở đây (BRIEF yêu cầu bộ file spoiler). `REFERENCE.md` là đáp án tham chiếu, nên coach chỉ mở khi người học đã nộp DESIGN.md hoặc xin xem.

## Số đo thật đã dùng (Postgres 18.6, 4 vCPU, `lab`)
Mọi số có script tái hiện trong thư mục `concurrency/` hoặc `scripts/` hoặc `queries.sql`. Số thay đổi giữa các lần chạy; kết luận (hơn kém cỡ bậc, 0 vs hàng nghìn) thì ổn định.
| Module | Phép đo | Kết quả |
|---|---|---|
| D01 | bytes/vote; buffers A2/A3/A4 | ~116 B; 733 / 9 / 13 |
| D02 | bytes/link, bytes/click; redirect | 179 B, 102 B; Index Scan 4 buffers |
| D03 | oversell 50 client × 40 lần, tồn 100 | naive bán 2000 (tồn còn 41); `UPDATE … WHERE on_hand >= 1` bán 100 |
| D04 | 20 client × 200 chuyển tiền, 10 tài khoản | khóa có thứ tự 4000/4000; không thứ tự 1386 deadlock (34.7%, mẫu nhỏ 33.5%), invariants vẫn đúng |
| D05 | 50 client tranh cùng khung giờ, 10 giây | EXCLUDE: 0 double booking; check-then-insert: 8 230 |
| D05 | bẫy cast int4 vs bigint trên GiST | 4 buffers vs 1 450 |
| D06 | counter nóng, 50 client, giữ lock 2 ms | 1 dòng 287 TPS; 16 mảnh 4 515 TPS |
| D06 | feed 20 bài, user follow 2020 người | pull 9 600 buffers; push 61; hybrid 1 429 |
| D07 | unread: watermark vs đếm dòng | 257 vs 12 614 buffers; gửi vào 1 hội thoại 1 367 TPS vs rải 8 432, 0 lỗ seq |
| D08 | noisy neighbor, 4 vCPU | tenant nhỏ 10 925 → 4 186 TPS khi có 4 client báo cáo cá voi |
| D08 | xóa tenant 400k dòng | DELETE 167 ms; DETACH 2.4 ms + DROP 12 ms |
| D08 | schema-per-tenant 1000 tenant | catalog +~17 MB, ALTER TABLE ×1000 = 333 ms, gộp 1 transaction → `out of shared memory` |
| D09 | poll `id > last_id` vs SKIP LOCKED | mất 6 937/11 157 vs 0 (writer giữ transaction 0–20 ms ngẫu nhiên) |
| D09 | dashboard 30 ngày trên 1M dòng fact | Seq Scan 8 336; BRIN chưa summarize 8 309; BRIN đã VACUUM 853; rollup 19 buffers |
| D09 | slot logical không tiêu thụ + ~400 MB WAL | giữ 390 MB, thư mục WAL 16 → 416 MB |
| D10 | pgbench scale 50, ladder connection | select-only 13k/106k/72k/67k TPS ở 1/4/16/64 client; 256 client bị từ chối (max_connections=100); TPC-B 1.1k/3.2k/6.8k/7.1k |
| D10 | partition vs bảng phẳng+BRIN, 1 ngày | 345 vs 355 buffers; truy vấn theo user 27 vs 18; retention DELETE 450 ms vs DETACH+DROP 2.6+87 ms |
| D10 | shard FDW 2 shard, truy vấn điểm | 138–147k TPS (1 node) / 6.3–11.1k (đúng shard) / 3.0–4.4k (hỏi cả 2 shard) |
| D10 | replica async, 4.7k TPS ghi | replay_lag max 68 ms, avg 7 ms; đọc ngay sau ghi thấy cũ 99.2%; remote_apply 0% |

## Chưa verify / chưa đo (nêu rõ để không dạy sai)
- **Citus** không có trong `postgres:18`; D10 chỉ dựng mô hình shard bằng `postgres_fdw`. Mọi nhận xét về Citus là kiến thức chung, chưa chạy.
- D10: **giao dịch xuyên shard bị lệch khi một server lỗi lúc commit** (postgres_fdw không 2PC mặc định): nêu là lập luận, chưa tái hiện.
- D03: lợi ích khóa theo thứ tự `product_id` chống deadlock là lập luận chuẩn; **chưa chạy thí nghiệm deadlock có/không sắp thứ tự** (D04 thì đã đo).
- D05: hai biện pháp giảm deadlock của EXCLUDE (advisory lock theo `resource_id`, hạ `deadlock_timeout`) **chưa đo**.
- D07: plan khi `conversations`/`messages` lớn hơn nhiều (60M dòng) chưa đo; hội thoại dài nhất trong seed chỉ 193 tin.
- D08: hiệu ứng generic plan của prepared statement chưa đo riêng; DELETE tenant 200M dòng chỉ ngoại suy.
- D06/D09: unfollow cleanup, `OrderCancelled` bù trừ chỉ mô tả, không dựng.
- Không sinh `shop_m`/`shop_l`: Tier D tự dựng dữ liệu trong `lab` (0.2–3M dòng) nên không phụ thuộc `shop_*`; số đo là xu hướng/ngoại suy có gắn nhãn, không phải số ở quy mô thật (1 tỉ dòng).
- Ngoại suy lên quy mô trong REFERENCE luôn kèm giả định. Không có số nào cho "quy mô thật" được đo.

## Quyết định thiết kế đáng chú ý
- **Mỗi khẳng định hành vi có một `ASSERT` hoặc một số đo.** Không để REFERENCE nói điều DB không chứng minh được. Khi số đo khác dự đoán, REFERENCE ghi số đo (ví dụ D10: partition *không* nhanh hơn bảng phẳng có BRIN; D06: aggregate xuyên shard qua FDW vẫn kéo cả 200k dòng).
- **Bẫy thật được phát hiện lúc dựng, giữ lại làm nội dung dạy:** D05 cast int4/bigint làm GiST mất cột dẫn (362× buffers); D05 deadlock khi hai `hold` chồng nhau (phải bắt cả `deadlock_detected`); D08 `ALTER ROLE … SET statement_timeout` không có hiệu lực khi `SET ROLE`; D08 FK check bỏ qua RLS (có lợi); D09 BRIN chưa summarize = không có index; D09 partial index outbox còn mục chết đến khi VACUUM.
- **Thí nghiệm concurrency chạy bằng `pgbench` + hàm SQL** (đúng ràng buộc "không dblink"): pgbench chạy được trong container chính; kết quả của mỗi thí nghiệm có bước đối chiếu bất biến (tổng tiền = 0, không lỗ seq, không double booking).
- **Dữ liệu seed không dùng `shop_*`** (khác tên miền với e-commerce D03 và còn D01/D02…): mỗi thiết kế dựng schema riêng `lab.dNN`, idempotent (`DROP SCHEMA … CASCADE`). D10 còn tạo `d10_s1`, `d10_s2`, `d10_pgb` (database).
- **`DESIGN.md` và `review.md` không soạn sẵn** (do người học viết và coach viết khi review); khác với tên file trong SKILL, bộ file của brief là `BRIEF/INTERVIEWER/REFERENCE/RUBRIC`.

## Vấn đề môi trường / sự cố đã gặp
- **Không push được**: repo cloud không có `git remote` (`origin` không tồn tại); `GH_TOKEN` không hợp lệ nên `gh` cũng không dùng được. Toàn bộ commit nằm local trên `content/d` (mỗi module một commit `feat(Dxx): …`). Cần người dùng cấu hình remote rồi `git push -u origin content/d` và mở PR vào `main`.
- Daemon Docker không chạy sẵn: `dockerd` được khởi động thủ công trong phiên.
- Một lần postmaster của container chính khởi động lại ("untracked child process exited with exit code 2") khi đang seed D05 sau một loạt thí nghiệm pgbench; recovery chạy bình thường, dữ liệu còn nguyên, chạy lại không tái hiện. Không xác định được nguyên nhân.
- D10 `replica_demo.sh` và `cdc_demo.sh` tự dựng/dọn container tạm (`d10-pri`, `d10-rep`, `d09-cdc`, mạng `d10net`), cần Docker.

## Đề xuất cho ROADMAP (không sửa)
- Tier D hiện không có "Pass" tự động; có thể thêm vào ROADMAP: D-module đạt khi interviewer chấm RUBRIC ≥ 22/30.
- `tools/verify.sh` có thể gọi `verify-designs.sh` để một lệnh kiểm cả hai.
