# P02 · Bài tập (B-tree index)

Bài 1–7 chạy trên **`shop_m`** (1M đơn; sinh bằng `bash datasets/shop/build.sh m`), bài 8 trên DB **`lab`** schema `p02`.
Bài làm của bạn (trừ ex09) là **các lệnh DDL** (`CREATE INDEX …`, `DROP INDEX …`) viết vào `answers/exNN.sql`; **query cho sẵn trong đề**, bạn không viết lại.
Check chạy DDL của bạn trong transaction (rồi ROLLBACK, DB không bị đổi), chạy `EXPLAIN (ANALYZE, BUFFERS)` cho query và kiểm: kết quả đúng, loại node, số buffers với **ngưỡng rộng** (không kiểm thời gian). Một vài bài kiểm thêm kích thước hoặc số index. Tự chấm: `bash tools/check.sh lessons/P02-btree-index 01`.
Với mỗi bài, ghi lại plan trước và sau (`EXPLAIN (ANALYZE, BUFFERS)`) và giải thích sự khác nhau.

**Pass:** "Tối ưu 5 query chậm": 7/9 bài, trong đó ex09 bắt buộc.

---

## 🟢 Cơ bản

### ex01 · Đơn của một khách
Query: `SELECT id, status, total_amount FROM orders WHERE user_id = 4242` (28 dòng). Hiện là Parallel Seq Scan, 11 929 buffers. Tạo index sao cho query đọc **< 100 buffers**.

### ex02 · 5 đơn gần nhất của khách
Query: `SELECT id, created_at FROM orders WHERE user_id = 4242 ORDER BY created_at DESC LIMIT 5`. Tạo **một** index sao cho plan **không có node Sort** và đọc < 30 buffers.

---

## 🟡 Kết hợp

### ex03 · Một index cho ba query
Ba query hay chạy: (a) `WHERE user_id = 4242` (28 dòng); (b) `WHERE user_id = 4242 AND status = 'delivered'` (25 dòng); (c) `WHERE user_id = 4242 AND created_at >= '2026-01-01' AND created_at < '2026-04-01'` (4 dòng). Tạo **đúng một** index mới trên `orders` để cả ba đọc **< 100 buffers**. Mỗi index thêm vào là một khoản phí ghi, nên hai index bị tính là thừa.

### ex04 · Báo cáo doanh thu theo khách (covering)
Query: `SELECT user_id, count(*) AS n, sum(total_amount) AS revenue FROM orders WHERE user_id BETWEEN 1000 AND 1999 GROUP BY user_id` (1 000 dòng). Hiện đọc ~11 000 buffers. Tạo index để plan là **Index Only Scan**, `Heap Fetches` ≤ 100 và tổng buffers < 1 000.

### ex05 · Hàng đợi đơn chưa xử lý
Query: `SELECT id, user_id, created_at FROM orders WHERE status IN ('pending','paid') ORDER BY created_at LIMIT 50`. Index mới phải làm cho query đọc **< 150 buffers**, không có Seq Scan, và **tổng kích thước các index mới ≤ 5 MB** (index đầy đủ trên `created_at` là 22.5 MB).

### ex06 · Báo cáo ngày sale (không đổi được query)
Team báo: báo cáo "đơn của ngày 11/11/2025 giờ Việt Nam" chạy hàng chục giây vì Seq Scan toàn bảng. Query do ORM sinh, **không sửa được**:
`SELECT id, total_amount FROM orders WHERE (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = DATE '2025-11-11'` (6 516 dòng). Tạo index để query đọc **< 300 buffers**.

### ex07 · Tìm theo tiền tố email
Team báo: ô tìm kiếm "email bắt đầu bằng …" của CS rất chậm. Query: `SELECT id, email FROM users WHERE email LIKE 'hung.pham88%'` (2 dòng). Hiện Seq Scan 1 526 buffers. Tạo index để đọc **< 30 buffers**.

---

## 🔴 Thực tế

### ex08 · "Ghi chậm vì quá nhiều index"
`lab.p02.ord` (300 000 dòng) có 5 index (xem `setup.sql`). Team báo `INSERT` vào bảng này chậm dần. Bốn query thật sự chạy: (1) `WHERE user_id = 777`; (2) `WHERE user_id = 777 ORDER BY created_at DESC LIMIT 3`; (3) `WHERE user_id = 777 AND created_at >= '2025-06-01' AND status = 'delivered'`; (4) `WHERE status = 'pending'` (297 dòng, hiếm). Viết các lệnh `DROP INDEX` để còn **≤ 2** index (không tính PK) mà cả bốn query vẫn đọc ít buffers (1–3 dưới 100; 4 dưới 600; Seq Scan là 2 500).

---

## 📏 Câu hỏi quy mô

### ex09 · Index lớn lên thế nào
Với `orders_pkey` và `WHERE id = 77`: **dự đoán trước** (ghi lại) số level của B-tree, dung lượng index và số buffers của một lần tra cứu ở `shop_m` (1M) và `shop_l` (10M); so với Seq Scan `WHERE user_id = 77`. Sau đó đo bằng `bt_metap`, `pg_relation_size`, `EXPLAIN (ANALYZE, BUFFERS)` và `bench/bench.sh` (cả hai query). Đối chiếu `solutions/ex09.md`. Trả lời: tra cứu bằng index gấp bao nhiêu lần khi N tăng 100×, Seq Scan thì sao?
