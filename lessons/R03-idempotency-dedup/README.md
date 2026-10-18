# R03 · Idempotency & dedup

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab` (schema `r03`, tạo bởi `setup.sql`) và `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Giải thích **idempotent** nghĩa là gì và vì sao retry là chuyện bình thường (mạng, timeout, bấm đúp).
- Dùng `INSERT … ON CONFLICT DO NOTHING / DO UPDATE` đúng, kể cả khi lô dữ liệu tự trùng bên trong.
- Xóa/phát hiện bản ghi trùng giữ bản mới nhất; chặn trùng bằng unique (partial) index theo luật nghiệp vụ.
- Viết hàm xử lý **idempotency key** an toàn khi hai request cùng key đến đồng thời.

---

## 1. Vì sao cần idempotent
Client gửi "trừ tiền đơn 5", mạng đứt trước khi nhận phản hồi, client gửi lại. Server không biết lần đầu đã chạy chưa. Thao tác **idempotent** nếu chạy N lần cho cùng kết quả như chạy 1 lần. `UPDATE … SET status = 'paid'` idempotent; `INSERT payment` và `UPDATE balance = balance - x` thì không. `shop_*` có 893 đơn bị trừ tiền hai lần cách nhau 3 giây (DIRTY.md).

## 2. `ON CONFLICT`
```sql
INSERT INTO r03.events (event_id, payload, received_at)
VALUES ('e2', '{"v": 9}', now())
ON CONFLICT (event_id) DO NOTHING;            -- bỏ qua nếu đã có

INSERT INTO r03.price_feed AS f (sku, price, src_updated_at) VALUES ('A1', 120, now())
ON CONFLICT (sku) DO UPDATE SET price = EXCLUDED.price, src_updated_at = EXCLUDED.src_updated_at
WHERE EXCLUDED.src_updated_at > f.src_updated_at;   -- chỉ ghi khi mới hơn
```
- `EXCLUDED` là dòng đang định chèn. `RETURNING` chỉ trả các dòng thật sự được chèn/sửa (dòng bị `DO NOTHING` hoặc không thỏa `WHERE` thì không trả).
- **Một lệnh không được chạm cùng một dòng hai lần.** Lô có hai dòng cùng khóa với `DO UPDATE` → lỗi `ON CONFLICT DO UPDATE command cannot affect row a second time` (SQLSTATE 21000). Dedupe lô trước bằng `DISTINCT ON (khóa) … ORDER BY khóa, thời_điểm DESC` (ex01, ex06).
- `WHERE` trong `DO UPDATE` tránh ghi vô ích: mỗi `UPDATE` tạo phiên bản dòng mới và ghi WAL dù giá trị không đổi (bloat, P07).
- `ON CONFLICT` đúng với đồng thời: nếu dòng xung đột chưa commit, lệnh **chờ** đến khi giao dịch kia commit/rollback rồi mới quyết định. `MERGE` (Postgres 15+) cũng làm upsert nhưng không đảm bảo như vậy dưới đồng thời (có thể báo unique violation); dùng `ON CONFLICT` cho upsert theo khóa.
- Sequence/identity vẫn tăng khi `DO NOTHING` bỏ qua dòng → id có "lỗ", bình thường.

## 3. Chặn trùng bằng ràng buộc
- Quy tắc "mỗi đơn tối đa một payment thành công" = unique index **partial**: `CREATE UNIQUE INDEX … ON payments (order_id) WHERE status = 'succeeded'` (ex04).
- Chuẩn hóa trước khi so: `UNIQUE (lower(btrim(email)))` là unique index trên **biểu thức**. Không có thì `users.email` ở `shop_*` cho phép `An@x.vn` và `an@x.vn ` cùng tồn tại.
- Dữ liệu cũ đang vi phạm thì dọn trước, tạo index sau (hoặc `CREATE UNIQUE INDEX CONCURRENTLY`, R10).

## 4. Xóa trùng, giữ bản mới nhất
```sql
DELETE FROM r03.contacts WHERE id IN (
  SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY updated_at DESC, id DESC) rn
                  FROM r03.contacts) t WHERE rn > 1);
```
Luôn có tie-breaker (`id`) để kết quả xác định. Muốn giữ dấu vết (tiền, kế toán) thì đánh dấu (`status = 'refunded'`) thay vì xóa. Chi phí tìm trùng: ex08.

## 5. Idempotency key
Client sinh một khóa (UUID) cho mỗi *ý định* (một lần bấm "Thanh toán") và gửi kèm mọi lần retry. Server lưu `key → kết quả`; gặp lại key thì trả kết quả cũ, không làm lại.
```sql
INSERT INTO idem_keys (key) VALUES ($1) ON CONFLICT (key) DO NOTHING;   -- FOUND = true: ta là người đầu tiên
```
**Không** viết `SELECT … nếu chưa có thì INSERT` (check-then-act): hai request đồng thời cùng thấy "chưa có". Unique constraint là thứ duy nhất trọng tài đúng dưới đồng thời (ex05). Lưu cả trạng thái "đang xử lý" nếu thao tác chạy lâu, và đặt thời hạn xóa key cũ (retention, R12).

## Bẫy hay gặp
1. `DO UPDATE` với lô có khóa trùng → lỗi 21000; `DO NOTHING` với lô có khóa trùng → giữ bản nào đến trước (không xác định).
2. Quên `WHERE` trong `DO UPDATE` → ghi đè bằng dữ liệu cũ và tạo bloat.
3. Chuẩn hóa không đủ: `lower()` mà thiếu `btrim()`; hoặc dấu/Unicode (`unaccent`, R11).
4. `UNIQUE` với NULL: NULL ≠ NULL (R01 ex04).
5. Check-then-act cho "chỉ làm một lần".

## Postgres-specific
- `ON CONFLICT` dựa trên *arbiter index*: `ON CONFLICT (cols)` phải khớp một unique index/constraint (kể cả partial thì phải lặp lại điều kiện `WHERE` của index).
- Postgres 17+ cho `MERGE … RETURNING` (kèm `merge_action()`); Postgres 18 cho `RETURNING old.col, new.col` ở `INSERT … ON CONFLICT DO UPDATE` để biết giá trị trước/sau (đã chạy thử trên 18.6). Trên bản cũ hơn không dùng được.
