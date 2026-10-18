# P09 · Bài tập (Query anti-patterns)

Bài 1–4, 6–8 chạy trên **`shop_m`** (1M đơn; `bash datasets/shop/build.sh m`); bài 5 trên DB `lab` schema `p09`.
**Định dạng bài làm** (`answers/exNN.sql`): lệnh DDL (index, nếu cần), rồi một dòng đúng `-- query`, rồi **câu SELECT viết lại**:
```sql
CREATE INDEX ON orders (...);   -- có thể không có
-- query
SELECT ...;
```
Check chạy DDL trong transaction (rồi ROLLBACK), so **kết quả giống query gốc** và kiểm số buffers (ngưỡng rộng), loại node. Không kiểm chuỗi SQL. Với mỗi bài hãy ghi lại `EXPLAIN (ANALYZE, BUFFERS)` trước/sau. Tự chấm: `bash tools/check.sh lessons/P09-anti-patterns 01`.

**Pass:** "Refactor 8 query": ex01–ex08 đúng ít nhất 7/8, kèm ex09.

---

## 🟢 Cơ bản

### ex01 · Đơn của một ngày
Query gốc: `SELECT count(*) FROM orders WHERE created_at::date = DATE '2026-09-11'` (Seq Scan, 11 929 buffers). Viết lại và tạo index để đọc **< 300 buffers**, kết quả y hệt (ngày theo giờ UTC của session).

### ex02 · Đơn của một khách (tham số sai kiểu)
Driver gửi `user_id` dưới dạng chuỗi nên ORM sinh: `SELECT id, total_amount FROM orders WHERE user_id::text = '4242'`. Sửa để đọc **< 100 buffers**, cùng kết quả.

---

## 🟡 Kết hợp

### ex03 · Tìm theo mã đơn hoặc email
Query gốc: `SELECT o.id FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id = 123456 OR u.email = 'nhung.le500@outlook.com'` (119 dòng). Viết lại + index để đọc **< 400 buffers** và không Seq Scan `orders`.

### ex04 · Trang 45 001 của danh sách đơn
Query gốc: `SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC OFFSET 900000 LIMIT 20`. Dòng cuối của trang trước là `(created_at, id) = ('2025-02-21 05:57:20.456226+00', 100001)`. Viết lại bằng keyset, cùng 20 dòng, **< 100 buffers**, không có node Sort.

### ex05 · Danh sách tài liệu (`SELECT *`)
`lab.p09.docs(id, kind, title, body)`: 300 dòng `long` có `body` 60 KB (TOAST). Màn hình danh sách chỉ hiện `id, title` nhưng code là `SELECT * FROM p09.docs WHERE kind = 'long'`. Viết lại để (đo bằng `EXPLAIN (ANALYZE, BUFFERS, SERIALIZE)`) dữ liệu gửi về client **< 100 kB** và tổng buffers kể cả serialize **< 200**.

### ex06 · "Có N kết quả"
Màn hình tìm kiếm hiện "hơn 1000 kết quả" cho `event_type = 'search'` (280 314 dòng trong 3.2M events); code hiện chạy `SELECT count(*) FROM events WHERE event_type = 'search'` (45 243 buffers). Viết câu trả về **1001** nếu có hơn 1000 dòng (số chính xác không cần), đọc **< 1000 buffers**.

---

## 🔴 Thực tế

### ex07 · "Trang quản trị chậm vì N+1"
Team báo: trang hiện 50 khách đầu và "đơn mới nhất của mỗi khách" chạy 51 query (mỗi query lọc `user_id` rồi `ORDER BY created_at DESC, id DESC LIMIT 1`), tổng gần nửa phút. Gộp thành **một** query trả `user_id, order_id, created_at` cho 50 khách có `user_id <= 50` (mỗi khách một dòng), đọc **< 1500 buffers**.

### ex08 · "Khách chưa từng mua"
Team báo: báo cáo "số khách chưa đặt đơn nào" `SELECT count(*) FROM users WHERE id NOT IN (SELECT user_id FROM orders)` chạy hàng giờ. (Check **không chạy thử** bản NOT IN vì quá lâu: nếu plan còn `SubPlan` thì tính sai.) Viết lại, kết quả **960**, đọc **< 15 000 buffers**.

---

## 📏 Câu hỏi quy mô

### ex09 · OFFSET sâu ở 10k, 1M, 10M
**Dự đoán** (ghi trước): thời gian và buffers của `OFFSET` tại 0%, 1%, 10%, 90% bảng ở `shop_m` (có và không có index), so với keyset. Rồi đo; ước lượng cho `shop_l`. Đối chiếu `solutions/ex09.md`.
