# P05 · Bài tập (GIN, GiST, BRIN)

Bài 1–4 chạy trên **`shop_m`** (1M đơn; `bash datasets/shop/build.sh m`; cần `pg_trgm`, đã có), bài 5–6 trên DB **`lab`** schema `p05` (script chấm tự chạy `setup.sql`, ~6 giây).
Bài làm là **các lệnh DDL** (`CREATE INDEX …` / `DROP INDEX …`) trong `answers/exNN.sql`; query cho sẵn trong đề. Check chạy DDL trong transaction (rồi ROLLBACK), `EXPLAIN (ANALYZE, BUFFERS)` query và kiểm kết quả đúng, **loại index (access method)**, số buffers, vài bài kiểm thêm kích thước. Tự chấm: `bash tools/check.sh lessons/P05-gin-gist-brin 01`.
Ghi lại plan trước/sau cho từng bài.

**Pass:** "Chọn đúng loại index cho 6 tình huống": ex01–ex06 đúng ít nhất 5/6, kèm ex07.

---

## 🟢 Cơ bản

### ex01 · Sự kiện của một sản phẩm (jsonb)
Query: `SELECT count(*) FROM events WHERE properties @> '{"product_id": 12345}'` (kết quả 40). Hiện Seq Scan ~45 000 page. Tạo index để đọc **< 200 buffers** bằng **GIN**.

### ex02 · Sự kiện một ngày (bảng append-only)
Query: `SELECT count(*) FROM events WHERE created_at >= '2026-09-29' AND created_at < '2026-09-30'` (18 166 dòng). Bảng sẽ lớn thêm hàng trăm triệu dòng; team muốn index rất nhỏ. Tạo **BRIN** sao cho tổng dung lượng index mới **≤ 1 MB** và query đọc **< 1 500 buffers**.

---

## 🟡 Kết hợp

### ex03 · Tìm email chứa chuỗi
Query: `SELECT id, email FROM users WHERE email ILIKE '%hung.pham88%'` (4 dòng). Hiện Seq Scan 1 526 buffers. Tạo index (giải pháp trigram) để đọc **< 600 buffers** và không còn Seq Scan.

### ex04 · Tìm sản phẩm theo từ
Query: `SELECT id, name FROM products WHERE to_tsvector('simple', name) @@ plainto_tsquery('simple', 'Samsung phụ kiện E4DA')` (1 dòng: `5 | Phụ kiện điện tử Samsung E4DA`). Hiện Seq Scan 398 buffers. Tạo index **GIN** để đọc **< 50 buffers**; query không được sửa.

### ex05 · Đặt phòng chồng giờ
`lab.p05.booking(id, room, during tstzrange)`, 300 000 dòng. Query: `SELECT id FROM p05.booking WHERE during && tstzrange('2025-06-01 10:00+00', '2025-06-01 12:00+00')` (35 dòng). Seq Scan 2 206 buffers. Tạo index để đọc **< 50 buffers**, dùng **GiST**. Thử trước cả B-tree trên `during` và giải thích vì sao nó không giúp.

---

## 🔴 Thực tế

### ex06 · "Có quá nhiều index trên bảng sự kiện"
Team báo `INSERT` vào `lab.p05.t` (400 000 dòng) chậm và dung lượng bảng phình. Ai đó đã thêm 6 index "cho chắc" (xem `setup.sql`). Sáu truy vấn thật đang chạy:
1. `SELECT count(*) FROM p05.t WHERE user_id = 5`
2. `SELECT sum(user_id) FROM p05.t WHERE status = 'delivered'` (90% dòng)
3. `SELECT sum(user_id) FROM p05.t WHERE flag` (50% dòng)
4. `SELECT count(*) FROM p05.t WHERE ts >= '2025-03-01' AND ts < '2025-03-02'`
5. `SELECT count(*) FROM p05.t WHERE payload @> '{"sku": 77}'`
6. `SELECT id FROM p05.t WHERE status = 'refunded'` (1% dòng)

Viết các `DROP INDEX` để bỏ **đúng những index mà không truy vấn nào ở trên dùng**, mà cả sáu truy vấn vẫn không chậm đi (≤ 1.5× buffers ban đầu + 50). Check chạy `EXPLAIN` thật để xác định index nào được dùng; không bỏ thừa, không giữ thừa. Giải thích vì sao `t_status_idx` ở lại còn `t_flag_idx` thì đi.

---

## 📏 Câu hỏi quy mô

### ex07 · Dung lượng và thời gian build theo N
Với `events` (`created_at` và `properties`): **dự đoán** dung lượng và thời gian build của B-tree `(created_at)`, BRIN `(created_at)`, GIN `jsonb_path_ops` và GIN `jsonb_ops` ở `shop_s` (32k events), `shop_m` (3.24M) và `shop_l` (≈ 32M). Sau đó đo (`CREATE INDEX` trong transaction + `ROLLBACK`; `\timing`, `pg_relation_size`). Đối chiếu `solutions/ex07.md`. Trả lời: loại nào tăng tuyến tính theo N, loại nào gần như không đổi? Điều gì xảy ra với BRIN nếu `UPDATE` làm xáo trộn thứ tự `created_at`?
