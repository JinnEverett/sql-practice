# R04 · Job queue với `FOR UPDATE SKIP LOCKED`

Đọc khoảng 10 phút. Mọi ví dụ chạy trên DB `lab`, schema `r04` (tạo bởi `setup.sql`). Cần kiến thức khóa dòng của P08 và transaction của P06 (nếu chưa học thì đọc phần 2 trước).

## Mục tiêu: sau buổi này bạn làm được
- Thiết kế bảng `jobs` và câu **nhận job** an toàn cho nhiều worker, không xử lý trùng, không chờ nhau.
- Xử lý lỗi: retry với exponential backoff, dead-letter, job treo do worker chết (visibility timeout).
- Dùng `LISTEN/NOTIFY` để đánh thức worker, và biết nó **không** bền.
- Đo chi phí câu nhận job khi hàng đợi lớn, chọn partial index, và biết lúc nào nên dùng broker ngoài.

---

## 1. Mô hình bảng
```sql
CREATE TABLE jobs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  payload jsonb NOT NULL,
  priority int NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','done','dead')),
  attempts int NOT NULL DEFAULT 0, max_attempts int NOT NULL DEFAULT 3,
  run_at timestamptz NOT NULL DEFAULT now(),         -- hẹn giờ / backoff
  locked_at timestamptz, locked_by text, last_error text);
```
Trạng thái đi: `queued → running → done`; lỗi: `running → queued` (kèm `run_at` mới) hoặc `→ dead`.

## 2. Nhận job: `FOR UPDATE SKIP LOCKED`
```sql
UPDATE jobs SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM jobs
            WHERE status = 'queued' AND run_at <= now()
            ORDER BY priority DESC, run_at, id
            LIMIT 1
            FOR UPDATE SKIP LOCKED)
RETURNING id, payload;
```
- `FOR UPDATE` khóa dòng được chọn. `SKIP LOCKED` bỏ qua các dòng đang bị khóa bởi transaction khác thay vì chờ. Hai worker chạy câu này cùng lúc nhận hai job **khác nhau**, không ai chờ ai.
- Thiếu `SKIP LOCKED` (chỉ `FOR UPDATE`): vẫn đúng nhưng worker thứ hai **chờ** worker thứ nhất commit, nên N worker thành xếp hàng một. Thiếu cả hai: hai worker chọn cùng một job.
- Nhận job và đánh dấu `running` trong **một câu lệnh**, commit ngay: khóa chỉ giữ vài mili giây. Xử lý job (có thể mất lâu) nằm **ngoài** transaction, không giữ khóa hay giữ connection mở (xem D-tier).
- Nhận theo lô: `LIMIT k` + `WHERE id IN (…)` (ex02): ít round trip hơn, nhưng worker chết thì cả lô treo.
- `SKIP LOCKED` cho kết quả **không nhất quán có chủ đích** (bỏ qua dòng đang khóa). Dùng cho hàng đợi, không dùng cho báo cáo.

## 3. Lỗi, retry, treo
- **Báo thất bại:** còn lượt thử → `queued` với `run_at = now() + base × 2^attempts` (exponential backoff; thêm jitter ngẫu nhiên ở bản thật để tránh thundering herd); hết lượt → `dead` (dead-letter, giữ để người xử lý) (ex03).
- **Worker chết:** job kẹt ở `running`. Định kỳ quét: `status = 'running' AND locked_at < now() - interval '5 minutes'` → trả về `queued`/`dead` (ex04). Thời gian chờ phải lớn hơn thời gian xử lý tối đa của một job, nếu không job vẫn đang chạy sẽ bị giao lần hai (at-least-once). Vì vậy **xử lý job phải idempotent** (R03).
- Hàng đợi trong Postgres cho ngữ nghĩa **at-least-once**. "Exactly-once" chỉ có khi hiệu ứng của job nằm cùng transaction với việc đánh dấu `done`.

## 4. `LISTEN/NOTIFY`
Thay vì poll mỗi giây, worker `LISTEN jobs` và được đánh thức khi có người `NOTIFY jobs`.
```sql
CREATE TRIGGER jobs_notify AFTER INSERT ON jobs FOR EACH ROW EXECUTE FUNCTION notify_new_job();  -- pg_notify('jobs', NEW.id::text)
```
- Thông báo gửi **khi commit**; transaction rollback thì không gửi gì. Trong một transaction, các `NOTIFY` giống hệt (cùng kênh, cùng payload) gộp thành một.
- **Không bền, không có lịch sử:** worker đang offline hoặc chưa `LISTEN` sẽ mất thông báo. Vì vậy luôn giữ vòng poll dự phòng (vd. 30 giây) và khi khởi động chạy câu nhận job trước. Payload tối đa khoảng 8000 byte; gửi `id`, không gửi dữ liệu.
- Mỗi worker `LISTEN` giữ một connection riêng (không đi qua PgBouncer transaction mode, O04).
- Ví dụ có kết quả thật từ 2 session: `solutions/ex07.md`.

## 5. Quy mô và chọn công cụ
- Câu nhận job phải rẻ ở mọi N: **partial index** `(priority DESC, run_at, id) WHERE status = 'queued'` chỉ chứa việc đang chờ. Đo ở ex08: 0.13 ms ở 1M dòng, trong khi index đầy đủ mất 176 ms.
- Hàng đợi ghi/UPDATE liên tục → dead tuple, bloat (P07). Dọn lịch sử `done`, hoặc partition theo ngày và drop partition (R12).
- Nên dùng hàng đợi Postgres khi: job sinh ra từ transaction nghiệp vụ (enqueue cùng commit với dữ liệu), tải vừa phải, muốn ít thành phần vận hành. Nên dùng broker (RabbitMQ/SQS/Kafka) khi: throughput rất lớn, nhiều consumer group, replay, độ trễ cực thấp, hoặc muốn tách tải khỏi database chính.

## Bẫy hay gặp
1. Giữ transaction mở trong lúc xử lý job (khóa + connection + bloat).
2. `SELECT … FOR UPDATE SKIP LOCKED` rồi `UPDATE` ở hai câu tách rời mà không cùng transaction: khóa nhả giữa hai câu.
3. Quên `run_at <= now()` (nhận job hẹn giờ) hoặc quên `status = 'queued'`.
4. Không có tie-breaker `id` trong `ORDER BY` (thứ tự không xác định).
5. Tin `NOTIFY` là đủ, không có poll dự phòng.
6. Job không idempotent trong hệ thống at-least-once.

## Cách chạy bài 2 session
Bài 5 và 6 chạy nhiều session bằng `dblink` (extension có sẵn trong image `postgres:18`, bộ chấm tự `CREATE EXTENSION IF NOT EXISTS dblink`). Bạn không cần tự mở nhiều cửa sổ; nếu muốn xem tận mắt, mở hai cửa sổ `psql` và thử như trong `solutions/ex07.md`.
