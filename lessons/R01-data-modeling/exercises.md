# R01 · Bài tập (Data modeling)

Bài 1–6 chạy trên **DB `lab`** schema `r01` (script chấm tự chạy `setup.sql` trước khi chấm); bài 7–8 trên **`shop_s`**; bài 9–10 tự đối chiếu.
Bài nào là DDL thì viết nhiều câu lệnh vào `answers/exNN.sql`; bộ chấm chạy chúng trong transaction rồi ROLLBACK.
Tự chấm: `bash tools/check.sh lessons/R01-data-modeling 01`.

**Pass:** 8/10 (ex09 tự chấm bằng danh sách review; ex10 tự đối chiếu số đo).

---

## 🟢 Cơ bản

### ex01 · Đưa về 1NF
`r01.legacy_orders.items` chứa chuỗi `'sku:qty,sku:qty'`. Bung thành một dòng cho mỗi (đơn, sản phẩm), `qty` là số nguyên.
- Cột: `order_no, sku, qty` · Sắp xếp: `order_no, sku`
- Kỳ vọng: **8 dòng**, dòng đầu `1001 | BUT | 10`

### ex02 · Tìm vi phạm phụ thuộc hàm
`r01.flat_sales` gom mọi thứ vào một bảng. Hai phụ thuộc hàm cần giữ: `customer_id → customer_name, customer_city` và `sku → product_name`. Liệt kê các cặp (khóa, thuộc tính) bị vi phạm. `unit_price` là giá lúc bán nên **không** thuộc danh sách này.
- Cột: `entity` (`'customer'`/`'product'`), `key` (text), `attribute` (tên cột), `n_values` (số giá trị khác nhau) · Sắp xếp: `entity, key, attribute`
- Kỳ vọng: **2 dòng**, dòng đầu `customer | 2 | customer_city | 2`

---

## 🟡 Kết hợp

### ex03 · Tách bảng phẳng thành 3NF
Từ `r01.flat_sales` tạo 4 bảng trong schema `r01`: `customers(customer_id, name, city)`, `products(sku, name)`, `orders(order_id, ordered_on, customer_id)`, `order_lines(order_id, sku, unit_price, qty)`; nạp dữ liệu bằng `INSERT … SELECT`. Quy tắc khi dữ liệu mâu thuẫn: lấy giá trị ở dòng có `line_id` **lớn nhất**. Khai báo PK, FK, `NOT NULL`, `CHECK (qty > 0)`, `CHECK (unit_price >= 0)`; `order_lines` có PK `(order_id, sku)`.
- Kiểm tra bằng bộ test: 4 / 3 / 6 / 10 dòng, dữ liệu mâu thuẫn đã được giải quyết, dữ liệu sai bị chặn (FK, PK, CHECK, NOT NULL).

### ex04 · Khóa duy nhất có NULL
`r01.price_list(product_id, region, price)`: `region IS NULL` nghĩa là giá toàn quốc. Mỗi cặp (sản phẩm, khu vực) chỉ được có **một** giá, kể cả khi `region` NULL. Thêm ràng buộc.
- Kiểm tra: chèn được giá toàn quốc cho sản phẩm 1, lần chèn thứ hai bị `23505`; các khu vực khác nhau vẫn chèn được.

### ex05 · Tag nhiều-nhiều
Thiết kế gắn tag cho `r01.catalog`: bảng `r01.tags(id identity, name)` và `r01.product_tags(product_id, tag_id)`. Yêu cầu: tên tag không trùng (**không phân biệt hoa/thường**), không có khoảng trắng đầu/cuối; một sản phẩm không gắn trùng tag; xóa sản phẩm thì dòng gắn tag tự mất; không xóa được tag đang dùng; tìm "sản phẩm theo tag" không phải Seq Scan.
- Kiểm tra bằng bộ test (ràng buộc + có index với `tag_id` đứng đầu).

### ex06 · Mỗi user một số điện thoại chính
`r01.user_phones(user_id, phone, is_primary)`. Một user có nhiều số, **tối đa một** số `is_primary`, và không lưu trùng cùng một số hai lần. Thêm ràng buộc.
- Kiểm tra bằng bộ test.

---

## 🔴 Thực tế

### ex07 · "Doanh thu quý 1 đổi mỗi lần marketing đổi giá"
Team báo: số doanh thu tháng 1–3/2026 nhìn lại hôm nay khác số đã báo cáo. Trên `shop_s`, cho mỗi tháng (giờ Việt Nam) trong quý 1/2026, tính doanh thu **đúng** (`unit_price` lúc mua) và doanh thu nếu tính bằng giá hiện tại của sản phẩm, rồi chênh lệch. Bỏ đơn `cancelled`/`refunded`.
- Cột: `month` (ngày đầu tháng), `revenue_at_purchase`, `revenue_at_current_price`, `diff` (đúng trừ hiện tại) · Sắp xếp: `month`
- Kỳ vọng: **3 dòng**, dòng đầu `2026-01-01 | 2236116000.00 | 2266902000.00 | -30786000.00`

### ex08 · Đối soát `total_amount`
Kế toán nghi ngờ cột dẫn xuất `orders.total_amount` đã lệch. Trên `shop_s`, liệt kê các đơn mà `total_amount` ≠ tổng(`quantity × unit_price`) + `shipping_fee` − `discount_amount` (đơn không có dòng hàng nào thì tổng dòng hàng = 0).
- Cột: `id, total_amount, expected_total, diff` (`total_amount − expected_total`) · Sắp xếp: `|diff|` giảm dần, trùng thì `id`
- Kỳ vọng: **20 dòng**, dòng đầu `1511 | 40176000.00 | 40129000.00 | 47000.00`

### ex09 · Mô hình hóa một domain có review (tự chấm)
Phòng khám đa khoa nhờ bạn thiết kế database: bệnh nhân có thể có nhiều số điện thoại; bác sĩ có một hoặc nhiều chuyên khoa; bệnh nhân đặt lịch hẹn với bác sĩ; mỗi lịch hẹn dùng một hoặc nhiều dịch vụ; giá dịch vụ thay đổi theo thời gian nhưng hóa đơn cũ phải giữ nguyên.
Việc cần làm (vào `answers/ex09.md` + `answers/ex09.sql`): vẽ ERD bằng mermaid, viết DDL (schema `r01_clinic`), liệt kê 3 chỗ bạn **chọn denormalize** hoặc **chọn không** và lý do. Sau đó đối chiếu với danh sách review trong `solutions/ex09.md`.

---

## 📏 ex10 · Câu hỏi quy mô: xóa 1 dòng khi FK không có index
```sql
BEGIN;
INSERT INTO users (email, full_name, country, created_at) VALUES ('tmp-fk@example.vn', 'Tmp', 'VN', now());
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM users WHERE email = 'tmp-fk@example.vn';
ROLLBACK;
```
1. **Dự đoán** (ghi vào `answers/ex10.md`): thời gian câu `DELETE` này ở `s`, `m`, `l`. Có bao nhiêu RI trigger chạy và mỗi cái làm gì? Sau khi thêm index vào các cột FK, thời gian ở `m` còn bao nhiêu?
2. Chạy ở `shop_s` và `shop_m` (đã có sẵn); ở `shop_l` nếu bạn đã sinh. Lặp lại sau khi `CREATE INDEX` trên `orders(user_id)` và `events(user_id)` (trong transaction rồi ROLLBACK).
3. Giải thích: vì sao xóa **một** dòng lại tốn thời gian tỉ lệ với kích thước bảng **khác**?

Lời giải và số đo thật: `solutions/ex10.md`.
