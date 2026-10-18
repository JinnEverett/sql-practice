# I09 · Bài tập (view, materialized view, function, trigger)

Mọi bài chạy trên DB **`lab`**, schema `i09` (script chấm tự chạy `setup.sql`: khách, sản phẩm, 12 đơn, `order_lines`, `price_history` và hai view dùng cho ex08).
Mỗi bài một hoặc vài lệnh DDL vào `answers/exNN.sql`. Bộ chấm chạy lệnh của bạn rồi thử hành vi thật (INSERT/UPDATE, đọc view…) trong `BEGIN … ROLLBACK`.
Tự chấm: `bash tools/check.sh lessons/I09-db-objects 01`.
Bảng: `i09.customers(id, name, email, status)` · `i09.products(id, name, price, stock)` · `i09.orders(id, customer_id, status, total, created_at)` · `i09.order_lines(id, order_id, product_id, quantity)` · `i09.price_history(id, product_id, old_price, new_price, changed_at)`.
Đơn 1–12 tạo từ 01/09/2026 09:00 giờ VN, mỗi đơn cách nhau 9 giờ. Múi giờ nghiệp vụ là giờ VN (`Asia/Ho_Chi_Minh`), server chạy UTC.

**Pass:** 6/8 (8 bài chấm tự động) + ex09 câu hỏi quy mô tự đối chiếu.

---

## 🟢 Cơ bản

### ex01 · View đơn hàng theo ngày VN
Tạo view `i09.v_orders_vn` gồm các đơn **không bị hủy** (`status <> 'cancelled'`), có đúng 5 cột theo thứ tự: `order_id`, `customer_name` (tên khách), `status`, `total`, `order_date` (ngày đặt **theo giờ VN**, kiểu `date`).
- Kỳ vọng: view có 9 dòng; đơn 3 (đặt 03:00 giờ VN ngày 02/09 = 20:00 UTC ngày 01/09) có `order_date = 2026-09-02`; đơn mới thêm sau đó xuất hiện ngay.

### ex02 · Hàm giá đã gồm VAT
Tạo `i09.vat_incl(amount numeric, rate numeric DEFAULT 0.08) RETURNS numeric`: `amount × (1 + rate)` làm tròn về **số nguyên** (VND). Đối số NULL trả NULL. Hàm phải đủ "sạch" để tạo được index trên `i09.vat_incl(total)`: chọn đúng `LANGUAGE`, độ ổn định và `STRICT`.
- Kỳ vọng: `vat_incl(100000) = 108000` · `vat_incl(100000, 0.1) = 110000` · `vat_incl(99999) = 107999`.

### ex03 · View khách đang hoạt động, ghi được an toàn
Tạo view `i09.v_active_customers (id, name, email, status)` chỉ gồm khách `status = 'active'`. Qua view này, ứng dụng phải `INSERT`/`UPDATE` được khách active, nhưng **không** được chèn khách `blocked` hay đổi một khách active thành `blocked` (câu lệnh phải lỗi, mã `44000`).
- Kỳ vọng: view có 4 dòng; `INSERT … 'blocked'` qua view lỗi; `UPDATE tên` qua view thành công và bảng gốc đổi theo.

---

## 🟡 Kết hợp

### ex04 · Doanh thu ngày: materialized view làm mới không khóa
Dashboard đang chậm vì mỗi lần mở lại tính doanh thu theo ngày từ `orders`. Tạo materialized view `i09.mv_daily_revenue (day, n_orders, revenue)`: theo ngày VN, số đơn và tổng `total` của các đơn **không hủy**. Ứng dụng sẽ làm mới bằng `REFRESH MATERIALIZED VIEW CONCURRENTLY` (người xem dashboard không được bị chặn), nên bạn phải chuẩn bị thêm điều kiện cho lệnh đó chạy được.
- Kỳ vọng: 5 dòng (ngày 01–05/09); ngày 01/09 doanh thu 150000; thêm đơn mới thì matview chưa thấy cho đến khi `REFRESH CONCURRENTLY`.

### ex05 · Hàm giảm giá đơn hàng
Tạo `i09.apply_discount(p_order_id int, p_pct numeric) RETURNS numeric` (PL/pgSQL): giảm `total` của đơn đúng `p_pct`% (làm tròn 2 chữ số) và **trả về tổng mới**. Quy tắc:
- `p_pct` phải trong 0–50, ngoài khoảng (hoặc NULL) → lỗi `invalid_parameter_value` (`22023`).
- Chỉ đơn ở trạng thái `pending` hoặc `paid` được giảm. Đơn không tồn tại hoặc đã `delivered`/`cancelled` → lỗi `no_data_found` (`P0002`) và **không đổi gì**.
- Kỳ vọng: đơn 1 (paid, 150000) giảm 10% → `135000.00`; đơn 9 giảm 12.5% → `1181250.00`; đơn 3 (delivered) bị từ chối.

### ex06 · Lịch sử đổi giá bằng trigger
Mỗi khi `price` của một sản phẩm **thực sự đổi**, ghi một dòng vào `i09.price_history (product_id, old_price, new_price)`. Không ghi khi chỉ đổi tên, khi `SET price = price`, hay khi `INSERT` sản phẩm mới. `UPDATE` hàng loạt nhiều sản phẩm một lúc phải ghi đủ từng sản phẩm. Lọc điều kiện ở mức trigger, không bằng `IF` trong thân hàm.
- Kỳ vọng: đổi giá sản phẩm 1 → 1 dòng `150000.00 → 160000.00`; `UPDATE products SET price = price * 2` (3 sản phẩm) → thêm 3 dòng.

---

## 🔴 Thực tế

### ex07 · "Kho bị âm"
Team kho báo: *"Cuối ngày thấy tồn kho Tai nghe âm 3, mà đã hết hàng từ sáng. Hai đơn được tạo gần như cùng lúc cho món cuối cùng."* Ứng dụng đang `SELECT stock` rồi mới `INSERT` dòng đơn và `UPDATE` kho (hai bước tách biệt). Hãy chặn ngay ở database: khi `INSERT` một dòng vào `i09.order_lines`, **trừ kho** `i09.products.stock` đúng `quantity`; nếu không đủ tồn kho thì **hủy** câu lệnh với mã `check_violation` (`23514`). Khi `DELETE` một dòng, **trả lại** kho. Một `INSERT` nhiều dòng mà dòng thứ hai hết hàng phải thất bại cả câu. Bài phải đúng cả khi hai session đặt hàng cùng lúc (đừng "đọc rồi ghi" ở hai bước).
- Kỳ vọng: kho Chuột 10 → mua 3 còn 7 → mua nốt 7 về 0 → mua thêm 1 bị chặn; xóa dòng 3 Chuột → kho +3; `INSERT` hai dòng 4 + 4 Bàn phím (kho 5) thất bại và kho giữ 5.

### ex08 · Thêm cột vào view đang chạy
Team báo cáo cần thêm cột `status` vào `i09.v_order_summary` (hiện có `order_id, customer_name, total`). View này đang được `i09.v_big_orders` (và ứng dụng khác) dùng, **không được** làm mất `v_big_orders`. Viết lệnh thêm cột `status` (lấy từ `orders`) mà không phải `DROP` view nào.
- Kỳ vọng: `v_order_summary` có 4 cột `order_id, customer_name, total, status`; `v_big_orders` vẫn còn và trả 7 dòng.

---

## 📏 ex09 · Câu hỏi quy mô: view hay matview, trigger hay set-based?
Hai tình huống trên `orders` 1M dòng (`shop_m`) và bảng 1M sản phẩm:
```sql
-- (1) Doanh thu theo ngày: tính lại mỗi lần (như một view) so với đọc từ materialized view
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, count(*), sum(total_amount)
FROM orders WHERE status <> 'cancelled' GROUP BY 1;
-- (2) Ghi lịch sử đổi giá cho 1M sản phẩm: (a) trigger FOR EACH ROW trong ex06  (b) một INSERT … SELECT riêng
```
1. **Dự đoán** (ghi vào `answers/ex09.md`): (1) mỗi lần tính tốn bao lâu, đọc 1 ngày từ matview tốn bao lâu, `REFRESH` tốn bao lâu và kích thước matview? Ở 10M đơn (`l`) con số đổi thế nào? (2) `UPDATE` 1M dòng có trigger chậm hơn không trigger bao nhiêu lần? Trigger có `WHEN` sai thì tốn gì? Ghi lịch sử bằng một `INSERT … SELECT` thì sao?
2. Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` và `\timing` (bảng lịch sử và matview tạo trong schema tạm, nhớ `DROP`).
3. Giải thích: node nào tốn thời gian, trigger làm gì cho từng dòng.

Lời giải và số đo thật: `solutions/ex09.md`.
