# I07 · Bài tập (JSONB & arrays)

Bài 1–7, 9 chạy trên **`shop_s`**; bài 8 trên DB **`lab`** schema `i07` (script chấm tự chạy `setup.sql`).
Mỗi bài một câu lệnh vào `answers/exNN.sql` (riêng ex08 được viết nhiều câu `UPDATE`). Tự chấm: `bash tools/check.sh lessons/I07-jsonb-arrays 01`.
`products.attributes` có các key `color`, `size`, `weight_g`, `warranty_months` (không phải sản phẩm nào cũng đủ). `events.properties` có `device`, `utm_source`, `product_id`, `query` tùy loại event.

**Pass:** 8/10 (9 bài chấm tự động + ex10 câu hỏi quy mô tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Đọc thuộc tính
Sản phẩm `id ≤ 10`: màu, size (text, không có ngoặc kép), cân nặng và số tháng bảo hành dạng **số nguyên** (không có thì NULL).
- Cột: `id, color, size, weight_g, warranty_months` · Sắp xếp: `id`
- Kỳ vọng: **10 dòng**, dòng đầu `1 | đen | (NULL) | 1900 | 24`

### ex02 · Đếm theo màu
Sản phẩm **đang bán** theo màu; sản phẩm không có thuộc tính màu ghi `'(không có)'`.
- Cột: `color, n_products` · Sắp xếp: `n_products` giảm dần, trùng thì `color`
- Kỳ vọng: **7 dòng**, dòng đầu `(không có) | 80`

### ex03 · Event thiếu thông tin thiết bị
Mỗi loại event: tổng số, số event **không có key** `device`, và % thiếu (làm tròn 2 chữ số).
- Cột: `event_type, n_events, n_missing_device, pct_missing` · Sắp xếp: `event_type`
- Kỳ vọng: **5 dòng**, dòng đầu `add_to_cart | 5562 | 63 | 1.13`

---

## 🟡 Kết hợp

### ex04 · Khám phá schema của jsonb
Liệt kê mọi key xuất hiện trong `products.attributes`: số sản phẩm có key đó, và các kiểu JSON của giá trị (`jsonb_typeof`), nối bằng `', '`.
- Cột: `key, n_products, types` · Sắp xếp: `n_products` giảm dần, trùng thì `key`
- Kỳ vọng: **4 dòng**, dòng đầu `weight_g | 200 | number`

### ex05 · Nguồn traffic
Các event `page_view` có `utm_source`: theo từng nguồn, số event và số **người xem** khác nhau. Người xem được định danh bằng `user_id` nếu đã đăng nhập, không thì bằng `anonymous_id`.
- Cột: `utm_source, n_events, n_visitors` · Sắp xếp: `n_events` giảm dần
- Kỳ vọng: **4 dòng**, dòng đầu `google | 2035 | 1272`

### ex06 · Trả đơn hàng dạng JSON cho API
Với các đơn `id ≤ 3`, dựng một object jsonb: `{"order_id", "status", "total", "items": [{"line", "product_id", "qty", "price"}, …]}` (`total` = `total_amount`, `price` = `unit_price`). Mảng `items` theo thứ tự `line_no`.
- Cột: `order_id, doc` (kiểu `jsonb`) · Sắp xếp: `order_id`
- Kỳ vọng: **3 dòng**; đơn 3: `{"items": [{"qty": 1, "line": 1, "price": 397000.00, "product_id": 13}], "total": 412000.00, "status": "cancelled", "order_id": 3}`

### ex07 · Đơn mua kèm
Tìm các đơn có **cả** sản phẩm 1 **và** sản phẩm 4. Cột `product_ids` là mảng mọi `product_id` của đơn, tăng dần (giữ trùng nếu một sản phẩm nằm ở nhiều dòng).
- Cột: `order_id, product_ids` · Sắp xếp: `order_id`
- Kỳ vọng: **63 dòng**, dòng đầu `144 | {1,4,13,138}`

---

## 🔴 Thực tế

### ex08 · Chuẩn hóa thuộc tính sản phẩm
DB `lab`, bảng `i07.products(id, name, attributes)`. Team catalog đổi chuẩn dữ liệu:
1. Sản phẩm **chưa có** `warranty_months` thì đặt `12`. Sản phẩm đã có thì **giữ nguyên**.
2. Đổi `weight_g` (gram) thành `weight_kg` (kg, số, làm tròn 3 chữ số lẻ). Bỏ key `weight_g`. Sản phẩm không có cân nặng thì không có `weight_kg`.
3. Bỏ key `size` nếu giá trị là JSON `null`.
- Kỳ vọng: sản phẩm 3 thành `{"color": "xám", "weight_kg": 0.175, "warranty_months": 12}`; sản phẩm 4 giữ `"warranty_months": 6`; sản phẩm 5 thành `{"warranty_months": 12}`.

### ex09 · Lọc bằng jsonpath
Tìm sản phẩm có `weight_g > 2000` **và** `warranty_months ≥ 12`. Viết bằng **jsonpath** (`@?` hoặc `@@`); viết bằng `->>` + ép kiểu cũng được chấm đúng.
- Cột: `id, name, weight_g, warranty_months` (số nguyên) · Sắp xếp: `id`
- Kỳ vọng: **13 dòng**, dòng đầu `5 | Ốp lưng Xiaomi E4DA   | 2395 | 24`

---

## 📏 ex10 · Câu hỏi quy mô: lọc jsonb ở 32 triệu event
```sql
SELECT count(*) FROM events WHERE properties @> '{"utm_source": "tiktok"}';
SELECT count(*) FROM events WHERE properties->>'utm_source' = 'tiktok';
```
1. **Dự đoán** (ghi vào `answers/ex10.md`): thời gian ở `s`, `m`, `l` khi không có index? Với index GIN `(properties jsonb_path_ops)` và index B-tree `((properties->>'utm_source'))`, câu nào dùng được index nào? Ở `l` có chắc nhanh hơn không?
2. Đo bằng `bench/bench.sh` và `EXPLAIN (ANALYZE, BUFFERS)` (tạo index trong `BEGIN … ROLLBACK`; ở `shop_l` mỗi index mất gần 30 giây).
3. Giải thích kết quả ở `l`.

Lời giải và số đo thật: `solutions/ex10.md`.
