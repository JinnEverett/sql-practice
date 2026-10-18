# I01 · Bài tập

Bài 1–5, 8, 9 chạy trên **`shop_s`**. Bài 6, 7 chạy trên DB **`lab`**, schema `i01` (script chấm tự chạy lại `setup.sql`).
Mỗi bài viết **một câu lệnh** (có thể bắt đầu bằng `WITH`) vào `answers/exNN.sql`. Module này luyện CTE: hãy chia bài toán thành các bước có tên.
Tự chấm: `bash tools/check.sh lessons/I01-cte 01`.

**Pass:** 8/10 bài, dùng ≤ 2 hint. Bài 10 là câu hỏi quy mô (bắt buộc ở Tier I, tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Khách chi tiêu vượt trội
Tổng chi tiêu của một khách = tổng `total_amount` các đơn `delivered` của khách đó. Tìm các khách có tổng chi tiêu **lớn hơn 3 lần mức trung bình của các khách** (trung bình tính trên những khách có ít nhất một đơn delivered).
- Cột: `user_id, total_spent`
- Sắp xếp: `total_spent` giảm dần, trùng thì `user_id` tăng dần
- Kỳ vọng: **45 dòng**, dòng đầu `1 | 5884970000.00`

### ex02 · Tháng kỷ lục mỗi năm
Doanh thu tháng = tổng `total_amount` của đơn `delivered`, tháng tính theo **giờ Việt Nam**. Với mỗi năm, tìm **tháng có doanh thu cao nhất**.
- Cột: `nam, thang, revenue` (`nam`, `thang` kiểu số nguyên)
- Sắp xếp: `nam` tăng dần
- Kỳ vọng: **3 dòng**, dòng đầu `2024 | 12 | 1554503000.00`

### ex03 · Tỉ trọng phương thức thanh toán 2026
Xét các giao dịch thanh toán **thành công** (`payments.status = 'succeeded'`) phát sinh trong **năm 2026 giờ VN** (theo `payments.created_at`). Với mỗi phương thức: số giao dịch, tổng tiền, và tỉ trọng tiền (%) trên **tổng tiền thành công** của năm, làm tròn 1 chữ số.
- Cột: `method, n_payments, amount, pct`
- Sắp xếp: `amount` giảm dần
- Kỳ vọng: **4 dòng**, dòng đầu `card | 2978 | 19109454000.00 | 53.1`

---

## 🟡 Kết hợp

### ex04 · Tăng trưởng so với tháng trước
Doanh thu tháng (giờ VN) = tổng `total_amount` của các đơn **không** `cancelled`/`refunded`. Với mỗi tháng từ **01/2026 đến 09/2026**, cho biết doanh thu, doanh thu **tháng liền trước**, và % tăng trưởng làm tròn 1 chữ số. Tháng 01/2026 cũng phải có số so sánh (với 12/2025). Chưa dùng window function.
- Cột: `thang` (dạng `YYYY-MM`), `revenue, prev_revenue, growth_pct`
- Sắp xếp: `thang` tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01 | 2203041000.00 | 3964423000.00 | -44.4`

### ex05 · Xem nhiều mà ít thêm giỏ
Từ bảng `events`: với mỗi sản phẩm, đếm số lần `product_view` và số lần `add_to_cart` (mã sản phẩm nằm ở `properties->>'product_id'`, là text). `cart_rate` = % số lần thêm giỏ trên số lần xem, làm tròn 1 chữ số. Chỉ xét sản phẩm có **ít nhất 50 lượt xem**. Sản phẩm chưa ai thêm giỏ thì `n_carts = 0`. Lấy **10 sản phẩm có `cart_rate` thấp nhất**.
- Cột: `product_id, name, n_views, n_carts, cart_rate`
- Sắp xếp: `cart_rate` tăng dần, trùng thì `product_id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `35 | Trà TH true milk 1C38 | 52 | 23 | 44.2`

### ex06 · Lưu trữ đơn đã hủy (data-modifying CTE)
DB `lab`, schema `i01`. Chuyển mọi đơn `cancelled` đặt **trước `2026-07-01 00:00` giờ VN** từ `i01.orders` sang `i01.orders_archive` (chép các cột `id, user_id, status, created_at, total`; `archived_at` để mặc định), và xóa chúng khỏi `i01.orders`, tất cả trong **một câu lệnh**.
- Kỳ vọng: `orders_archive` có `id` = 1, 3, 8. Đơn 4 (đúng 00:00 ngày 01/07) **ở lại**. `orders` còn **7 dòng**.

### ex07 · Tạo đơn kèm dòng hàng trong một câu lệnh
DB `lab`. Khách `7` đặt một đơn `pending` lúc `2026-10-17 10:00` giờ VN, gồm 3 dòng hàng: (dòng 1, sản phẩm 101, SL 2, đơn giá 100000), (dòng 2, sản phẩm 205, SL 1, đơn giá 250000), (dòng 3, sản phẩm 330, SL 3, đơn giá 15000). `total` của đơn **phải được tính từ các dòng hàng**, không gõ tay. `id` đơn để bảng tự sinh. Viết **một câu lệnh** chèn cả đơn lẫn dòng hàng.
- Kỳ vọng: đơn mới `id = 11`, `total = 495000.00`, có 3 dòng hàng trỏ về đơn 11.

---

## 🔴 Thực tế

### ex08 · Khách mới và tỉ lệ quay lại
Growth team hỏi: "Mỗi tháng năm 2026 có bao nhiêu **khách mới**, và bao nhiêu % trong số đó **mua lại trong vòng 30 ngày**?"
- Khách mới của tháng X: khách có **đơn đầu tiên** (bỏ qua đơn `cancelled`) đặt trong tháng X (giờ VN). Chỉ xét đơn đầu từ 01/2026 đến 09/2026.
- Mua lại trong 30 ngày: có ít nhất một đơn **khác** (không `cancelled`) đặt **sau** đơn đầu và **không quá 30 ngày** tính từ thời điểm đơn đầu.
- Cột: `thang` (`YYYY-MM`), `n_new, n_repeat_30d, pct_repeat` (làm tròn 1 chữ số)
- Sắp xếp: `thang` tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01 | 41 | 13 | 31.7`

### ex09 · Đối soát tổng tiền đơn hàng
Kế toán phát hiện vài đơn có `total_amount` **không khớp** với `tổng (quantity × unit_price) của các dòng hàng + shipping_fee − discount_amount`. Liệt kê các đơn lệch.
- Cột: `order_id, total_amount, expected, diff` (`diff = total_amount − expected`)
- Sắp xếp: độ lệch tuyệt đối giảm dần, trùng thì `order_id` tăng dần
- Kỳ vọng: **20 dòng**, dòng đầu `1511 | 40176000.00 | 40129000.00 | 47000.00`

---

## 📏 ex10 · Câu hỏi quy mô: CTE có làm query chậm đi không?
Hai câu sau cho **cùng kết quả**:
```sql
-- A
WITH o AS MATERIALIZED (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
-- B
WITH o AS (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
```
1. **Dự đoán trước** (ghi vào `answers/ex10.md`): ở `shop_s`, `shop_m`, `shop_l`, mỗi câu mất khoảng bao lâu? Plan có khác nhau không? Có tràn đĩa không?
2. Lưu mỗi câu vào một file rồi đo: `bench/bench.sh <file> --scales s,m,l`.
3. Giải thích điểm gãy. Khi nào Postgres **tự** materialize một CTE?

Lời giải và số đo thật: `solutions/ex10.md`.
