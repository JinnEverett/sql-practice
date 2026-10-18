# Báo cáo nhóm `r` (R01–R12)

Branch `content/r`. Môi trường verify: Docker `postgres:18` (18.6) dựng bằng `docker compose -f env/docker-compose.yml up -d` (tự chạy `dockerd` vì VM chưa có daemon), `shop_xs`, `shop_s`, `shop_m` sinh bằng `datasets/shop/build.sh`. **Không sinh `shop_l`** (theo brief).

## Kết quả `bash tools/verify.sh lessons/R*`
**86 đạt · 17 tự đối chiếu (manual, demo SQL chạy được, có `.md` lời giải) · 0 lỗi**; mọi `trap` bị bắt, mọi `alt` được nhận, mọi `**N dòng**` trong `exercises.md` khớp đáp án. Chạy lại `verify.sh` cho F09 và I04 sau khi sửa `tools/lib.sql`: vẫn xanh.

## Danh sách module và mức verify
| Module | Thư mục | Bài (tự động / tự đối chiếu) | Verify | Ghi chú |
|---|---|---|---|---|
| R01 Data modeling | `R01-data-modeling` | 8 / 2 (ex09 thiết kế phòng khám, ex10 📏) | ✅ trên 18.6 | ex09.sql dựng schema tham chiếu `r01_clinic` |
| R02 Pagination | `R02-keyset-pagination` | 8 / 1 (ex09 📏) | ✅ | ex08 chạy trên `shop_m` |
| R03 Idempotency & dedup | `R03-idempotency-dedup` | 7 / 1 (ex08 📏) | ✅ | ex05 mô phỏng 2 session bằng dblink; đã thử `RETURNING old/new` và `MERGE … RETURNING` trên 18.6 |
| R04 Job queue | `R04-job-queue` | 6 / 2 (ex07 NOTIFY, ex08 📏) | ✅ | ex05 (2 session), ex06 (3 worker song song) bằng dblink |
| R05 Lịch sử dữ liệu | `R05-history-audit` | 8 / 1 (ex09 📏) | ✅ | |
| R06 Dữ liệu cây | `R06-hierarchical-data` | 8 / 1 (ex09 📏) | ✅ | 4 cách biểu diễn (adjacency, ltree, closure, nested set) |
| R07 Analytics SQL | `R07-analytics-sql` | 8 / 1 (ex09 📏) | ✅ | |
| R08 Concurrency bugs | `R08-concurrency-bugs` | 5 / 3 (ex01, ex07, ex08 📏) | ✅ | ex02, ex04, ex05, ex06 chấm bằng nhiều session thật |
| R09 Multi-tenancy & RLS | `R09-multitenancy-rls` | 6 / 1 (ex07 📏) | ✅ | tạo 2 role NOLOGIN ở mức cluster (setup) |
| R10 Migrations | `R10-zero-downtime-migrations` | 7 / 2 (ex05 kế hoạch, ex09 📏) | ✅ | dùng event trigger để kiểm đường đi của DDL |
| R11 Search | `R11-search` | 7 / 1 (ex08 📏) | ✅ | |
| R12 Partitioning | `R12-partitioning-timeseries` | 8 / 1 (ex09 📏) | ✅ | |

**Chưa verify:** mọi thí nghiệm ở quy mô `shop_l`/10M (ghi rõ "chưa chạy" trong từng `ex..md`). Không có module nào dùng tính năng riêng của 18 mà không chạy được; các tính năng đã kiểm trên 18.6: `RETURNING old./new.`, `MERGE … RETURNING merge_action()`, `UNIQUE NULLS NOT DISTINCT`, `security_invoker`, `string_to_table`, labels `ltree` 1000 ký tự và dấu `-`, async I/O không dùng.

## Số đo thật đã dùng (một lần chạy trừ khi ghi "trung vị"; Docker trên VM cloud 4 lõi, `shared_buffers=256MB`, `work_mem=4MB`)
- **R01 ex10:** xóa 1 user khi FK không có index: 2.9–5.4 ms (s), 224–238 ms (m) so với 0.3 / 5 ms khi có index (3 lần chạy).
- **R02 ex09:** OFFSET sâu vs keyset ở 1M/5M…: m có index OFFSET 900 000 = 190 ms (14 199 buffer) vs keyset 0.115 ms (4 buffer); không index 483 ms vs 37 ms (trung vị 3).
- **R03 ex08:** tìm trùng: GROUP BY 92 ms, window 321 ms, self-join 827 ms ở 100k user (m); payment trùng 507 / 660 ms ở 1M.
- **R04 ex08:** câu nhận job 1 000 queued trong N = 10k/100k/1M: không index 1.0/5.8/51 ms; index đầy đủ 1.4/15.8/**176** ms (tệ hơn); partial 0.16/0.11/0.13 ms.
- **R05 ex09:** audit trigger UPDATE toàn bảng: ×4.8 thời gian, WAL 697 vs 242 MB, bảng audit 394 MB ở 1M (một lần chạy).
- **R06 ex09:** 4 cách biểu diễn cây ở 11k/111k/1.1M nút: Q1/Q2/Q3, di chuyển cây con: adjacency 0.2 ms, ltree 244 ms, closure 624 ms, nested set 7 292 ms (một lần chạy), dung lượng 81–567 MB.
- **R07 ex09:** sessionization 3.2M event: 10.8 s (4MB), 12.3 s (256MB), 8.1 s (index biểu thức), 6.8 s (`COLLATE "C"`).
- **R08 ex08:** pgbench 10 giây: dòng nóng 3 135 → 2 330 TPS (1 → 16 client) vs 16 dòng phân mảnh 2 973 → 14 676 TPS; `synchronous_commit=off` cho số khác (xem md).
- **R09 ex07:** RLS không tạo chênh lệch plan khi policy là biểu thức; policy gọi hàm plpgsql VOLATILE chậm ×19 (71.9 vs 3.8 ms ở 1M).
- **R10 ex05/ex09:** `ALTER COLUMN TYPE bigint` chặn đọc+ghi 8.6 s ở 5M dòng; `CREATE INDEX` chặn ghi 3.1 s; `VALIDATE CONSTRAINT` 344 ms không chặn; hoán đổi expand/contract ≈ 12 ms ở 1M.
- **R11 ex08:** trigram/FTS/partial index: 10.6× / 44× / 1.9× nhanh hơn ở m.
- **R12 ex09:** partition 12 tháng vs bảng thường (không index: 12× ít buffer; có index: không nhanh hơn); planning time 0.44 → 9.1 ms với 1 460 partition; retention WAL 10 KB vs 4.7–23 MB.
Mọi con số có thể tái hiện bằng `solutions/exNN.sql` của bài tương ứng (bản nhỏ) hoặc đổi tham số như ghi trong file.

## Quyết định thiết kế đáng chú ý
1. **Mô phỏng nhiều session bằng `dblink`** (R04 ex05/06, R03 ex05, R08, R10 ex08). Brief nói `env/init` không cài dblink; bộ chấm tự `CREATE EXTENSION IF NOT EXISTS dblink` (cần superuser = user `postgres` của workspace; extension nằm trong image `postgres:18` và gói `postgresql-contrib`). Mẫu chung: session A mở `BEGIN`, gọi hàm của người học, giữ transaction mở (`pg_sleep`), session B chạy trong lúc đó. Kết quả đồng thời kiểm tra bằng invariant (stock không âm, mỗi job xử lý đúng 1 lần, ít nhất 1 bác sĩ trực…), không bằng thời gian tuyệt đối, trừ hai chỗ có ngưỡng thời gian rộng (xem "Rủi ro").
2. **Event trigger làm "dấu vết đường đi"** (R10 ex02, ex04, ex07, ex08; R12 ex06): bộ chấm tạo event trigger ghi lại, tại mỗi lệnh DDL của bài làm, trạng thái catalog (có ràng buộc NOT VALID không, CHECK đã validate chưa, `lock_timeout` hiệu lực, `current_query()` có `CONCURRENTLY`/`ATTACH PARTITION` không). Nhờ đó chấm được "đã đi qua đường an toàn" chứ không chỉ "trạng thái cuối đúng". Dùng `current_query()` để nhận biết `CONCURRENTLY` là kiểm tra theo chuỗi duy nhất của bộ bài; chấp nhận vì từ khóa đó chính là yêu cầu.
3. **Đo bằng `relfilenode` và `xmin`** (R10 ex01, ex03): không viết lại bảng ⇔ `relfilenode` không đổi; không UPDATE ⇔ `xmin` mọi dòng giữ nguyên; backfill theo lô ⇔ nhiều giá trị `xmin` với mỗi nhóm ≤ kích thước lô.
4. **Dữ liệu cố định kèm "bẫy cài sẵn"**: index INVALID thật (R10 ex04: `CREATE UNIQUE INDEX CONCURRENTLY` thất bại trong `setup.sql`, tắt `ON_ERROR_STOP` quanh lệnh đó), role `r09_app`/`r09_support` (R09, nhờ `SET ROLE` để RLS có hiệu lực vì superuser bypass).
5. **📏 câu hỏi quy mô** của mọi module dùng số đo thật; nhiều kết quả phản trực giác được giữ nguyên làm bài học: index đầy đủ tệ hơn không index (R04), tăng `work_mem` không giúp (R07), partition không nhanh hơn khi đã có index (R12), index B-tree tệ hơn Seq Scan (đã có ở I07, không lặp lại).
6. **Đã bỏ vài ý định ban đầu** khi số đo không ủng hộ hoặc kiểm không đáng tin: kiểm số buffer của GIN trigram với mẫu quá phổ biến (1 746 dòng gần như chạm mọi page), chọn mẫu 59 dòng; trap "OFFSET giả cursor" của R02 ex06 hóa ra đúng ngữ nghĩa nên bỏ; trap `lower(unaccent())` ở R11 ex04 phải đổi truy vấn thành `op lung samsug` vì `pg_trgm` đã bỏ qua hoa/thường.

## Thay đổi ở `tools/`
- `tools/lib.sql`: **thêm vào cuối** (chú thích `[nhóm r]`) ba hàm `pg_temp.bg_start(conn, q, db)`, `pg_temp.bg_wait(conn)`, `pg_temp.bg_run(q, db)` bọc `dblink_connect`/`dblink_send_query`/`dblink_get_result` để chạy session nền. Không đổi hàm cũ. Cần `CREATE EXTENSION dblink` ở bộ chấm gọi chúng.
- `tools/CONTENT_PLAN.md`: dòng `R` → 🧪. Không sửa `check.sh`, `verify.sh`, `pg-runner.sh`, ROADMAP, `datasets/shop/README.md`.

## Rủi ro và việc cần để mắt
- **Bộ chấm dùng thời gian** (có margin rộng): R04 ex05 (`lock_timeout=300ms` cho session B, A giữ 1.5 s); R08 ex02/04/05/06 (sleep 0.1–1.2 s giữa các session); R10 ex08 (truy vấn đến sau phải chờ < 0.6 s trong khi khóa của A là 1.5 s; `lock_timeout` của người học phải ≲ 500 ms). Trên máy rất chậm hoặc rất tải có thể flaky; không thấy flaky trong các lần chạy ở đây (mỗi bài đã chạy ≥ 3 lần).
- **Bộ chấm có tác dụng phụ ngoài transaction:** các bài đồng thời (R03 ex05, R04, R08, R10 ex03/04/08) không bọc `BEGIN … ROLLBACK` vì session khác phải thấy dữ liệu đã commit; chúng dựa vào `-- reset` (chạy lại `setup.sql`) để về trạng thái ban đầu và tạo/xóa event trigger. Không để lại gì ngoài schema của bài và role R09.
- **R09 tạo 2 role mức cluster** (`r09_app`, `r09_support`, NOLOGIN) và R10 setup in một lỗi `could not create unique index` có chủ ý (index INVALID). Cả hai nằm trong README/exercises của bài.
- **ROADMAP:** không có chỗ cần đổi thứ tự; R06 "So sánh 3 cách" được nâng lên bốn cách (thêm adjacency làm cơ sở) và R12 nhấn mạnh vận hành hơn tốc độ đọc theo số đo. Có thể cân nhắc thêm vào mô tả R08 (write skew, deadlock) và R10 (lock queue) vì bài đã bao quát.
- **Git:** môi trường soạn bài **không có remote `origin`** (`git remote -v` rỗng, `GH_TOKEN` là `proxy-injected` và `gh auth status` báo token không hợp lệ), nên chưa push được. Toàn bộ nằm trong các commit cục bộ `feat(R01)` … `feat(R12)` trên branch `content/r`. Cần thêm remote rồi `git push -u origin content/r` và mở PR vào `main`.
