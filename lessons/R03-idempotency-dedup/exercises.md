# R03 · Bài tập (Idempotency & dedup)

Bài 1, 2, 4, 5, 6 chạy trên **DB `lab`** schema `r03` (script chấm tự chạy `setup.sql`); bài 3, 7 trên **`shop_s`**; bài 8 là câu hỏi quy mô (tự đối chiếu).
Bài DML/DDL viết trực tiếp lệnh vào `answers/exNN.sql`; bộ chấm chạy chúng rồi so trạng thái bảng hoặc chạy bộ test.
Tự chấm: `bash tools/check.sh lessons/R03-idempotency-dedup 01`.
Bài 5 mô phỏng **2 session đồng thời** bằng `dblink` (bộ chấm tự `CREATE EXTENSION IF NOT EXISTS dblink`, cần quyền superuser như user `postgres` của workspace): session A gọi hàm của bạn và giữ transaction mở 1.2 giây, trong lúc đó session chính gọi cùng key.

**Pass:** 6/8 (7 bài chấm tự động + ex08 tự đối chiếu số đo).

---

## 🟢 Cơ bản

### ex01 · Nạp lô event idempotent
`r03.events(event_id PK, payload, received_at)` đã có `e1`, `e2`. Lô mới nằm ở `r03.inbox`: có event trùng với bản đã lưu (`e2`) và event xuất hiện nhiều lần ngay trong lô (`e3`, `e5`). Nạp lô vào `events` bằng **một câu `INSERT`** sao cho: event đã có thì giữ nguyên (không ghi đè); event lặp trong lô thì giữ bản có `received_at` **mới nhất**; chạy lại câu lệnh nhiều lần không đổi kết quả.
- Kiểm tra: trạng thái bảng `events` sau khi chạy (5 dòng, `e2` vẫn `v = 1`, `e3` có `v = 2`, `e5` có `v = 1`)

### ex02 · Xóa trùng giữ bản mới nhất
`r03.contacts` có email trùng khi bỏ khác biệt hoa/thường và khoảng trắng đầu/cuối. Mỗi người chỉ giữ **một** dòng: `updated_at` mới nhất, trùng thì `id` lớn nhất. Xóa các dòng còn lại.
- Kiểm tra: trạng thái bảng `contacts` sau khi chạy (còn đúng 5 dòng: id 3, 4, 6, 7, 9)

---

## 🟡 Kết hợp

### ex03 · Tài khoản trùng trên shop
Trên `shop_s`, tìm các nhóm tài khoản có cùng email sau khi bỏ khác biệt hoa/thường và khoảng trắng đầu/cuối; chỉ liệt kê nhóm có ≥ 2 tài khoản.
- Cột: `norm_email, n_users, user_ids` (mảng `id` tăng dần) · Sắp xếp: `norm_email`
- Kỳ vọng: **5 dòng**, dòng đầu `dung.pham404@gmail.com | 2 | {404,407}`

### ex04 · "Mỗi đơn chỉ được trừ tiền một lần"
`r03.payments` có đơn bị `succeeded` hai, ba lần (đơn 10 và 13). Kế toán yêu cầu: giữ lại payment `succeeded` **sớm nhất** của mỗi đơn, các bản trùng sau đó chuyển thành `'refunded'` (không xóa dòng nào); sau đó database phải **tự chặn** việc ghi payment `succeeded` thứ hai cho một đơn, nhưng vẫn cho nhiều payment `failed`/`refunded` trên cùng đơn.
- Kiểm tra bằng bộ test (trạng thái dữ liệu + ràng buộc)

### ex05 · Hàm `charge` idempotent (2 session)
Viết hàm `r03.charge(p_key text, p_order bigint, p_amount numeric) RETURNS bigint` dùng bảng `r03.idem_keys(key PK, payment_id)` và `r03.pay2(id, order_id, amount, created_at)`: lần đầu với một `key` thì tạo một dòng `pay2` và trả `id`; mọi lần sau với cùng `key` trả lại đúng `id` đó, không tạo thêm. Phải đúng cả khi hai request cùng key đến **đồng thời**.
- Kiểm tra bằng bộ test (gọi lặp, key khác nhau, và đua hai session)

---

## 🔴 Thực tế

### ex06 · "Đồng bộ giá từ nhà cung cấp làm DB phình"
Mỗi đêm nhà cung cấp gửi lô giá vào `r03.price_batch` (có SKU xuất hiện hai lần, có giá cũ hơn bản đang có, có giá không đổi). Viết **một câu** nạp lô vào `r03.price_feed` sao cho: SKU mới thì chèn; SKU đã có chỉ cập nhật khi bản trong lô **mới hơn** (`src_updated_at`) **và** giá thật sự khác; không ghi đè bản cũ hơn; không ghi lại dòng không đổi. Câu lệnh phải `RETURNING sku` để job biết SKU nào thật sự thay đổi.
- Kiểm tra: trạng thái bảng `price_feed` **và** output của câu lệnh (A1, A4, A5; không có A2, A3)

### ex07 · Danh sách payment cần hoàn tiền
Trên `shop_s`, mỗi đơn có nhiều payment `succeeded` thì bản đầu tiên (sớm nhất, trùng thì `id` nhỏ nhất) là hợp lệ, các bản sau cần hoàn tiền. Liệt kê các bản cần hoàn tiền, kèm số giây sau bản đầu tiên.
- Cột: `order_id, payment_id, amount, seconds_after_first` (số nguyên) · Sắp xếp: `order_id, payment_id`
- Kỳ vọng: **9 dòng**, dòng đầu `1689 | 1774 | 3748000.00 | 3`

---

## 📏 ex08 · Câu hỏi quy mô: tìm bản ghi trùng
```sql
-- A
SELECT lower(btrim(email)), count(*) FROM users GROUP BY 1 HAVING count(*) > 1;
-- B
SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(btrim(email)) ORDER BY created_at, id) rn FROM users) t WHERE rn > 1;
-- C
SELECT a.id FROM users a JOIN users b ON lower(btrim(a.email)) = lower(btrim(b.email)) AND a.id > b.id;
```
1. **Dự đoán** (ghi vào `answers/ex08.md`): thứ tự nhanh → chậm của A, B, C ở `m` (100k user) và `l` (1M user). Cái nào tràn ra đĩa với `work_mem = 4MB`? Tìm payment `succeeded` trùng trên 1M payment tốn cỡ nào so với tìm email trùng trên 100k user?
2. Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` hoặc `bench/bench.sh` ở `s` và `m` (và `l` nếu bạn đã sinh).
3. Giải thích: vì sao "ngăn trùng lúc ghi" rẻ hơn "dọn trùng sau"?

Lời giải và số đo thật: `solutions/ex08.md`.
