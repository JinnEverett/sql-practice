# F05 · Bài tập

Tất cả các bài chạy trên **`shop_s`**. Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F05-joins 01`. Dòng `Cột:` sẽ báo ngay nếu tên cột lệch đề.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

---

## 🟢 Cơ bản

### ex01 · Đơn kèm tên khách
Các đơn có `id` từ 5001 đến 5010, kèm tên khách đặt đơn.
- Cột: `order_id, full_name, status, total_amount`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `5001 | Bùi Văn Hoa | delivered | 435000.00`

### ex02 · Chi tiết đơn số 1
Liệt kê các dòng hàng của đơn `id = 1`, kèm tên sản phẩm và tên danh mục của sản phẩm.
- Cột: `line_no, product_name, category_name, quantity, line_total` (`line_total` = số lượng × đơn giá lúc mua)
- Sắp xếp: `line_no` tăng dần
- Kỳ vọng: **4 dòng**, dòng đầu `1 | Trà Trung Nguyên D67D | Trà | 1 | 105000.00`

### ex03 · Khách chưa mua lần nào
Tìm các khách **chưa từng đặt đơn nào**. Chỉ dùng JOIN, chưa dùng subquery.
- Cột: `id, full_name, created_at`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu là khách `467`

### ex04 · Số đơn của khách Nhật
Với **mọi** khách ở Nhật (`country = 'JP'`), cho biết số đơn đã đặt, **kể cả khách 0 đơn**.
- Cột: `id, full_name, n_orders`
- Sắp xếp: `n_orders` giảm dần; trùng thì `id` tăng dần
- Kỳ vọng: **34 dòng**, dòng đầu `126 | Phạm Ngọc Hải | 25`

---

## 🟡 Kết hợp

### ex05 · Cây danh mục
Liệt kê mọi danh mục kèm tên danh mục cha. Danh mục gốc (không có cha) ghi `(gốc)`.
- Cột: `id, name, parent_name`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **42 dòng**, dòng đầu `1 | Thời trang | (gốc)`

### ex06 · Top brand tháng 9
Top 5 brand có doanh thu cao nhất từ các đơn **đã giao** (`delivered`) đặt trong **tháng 9/2026, giờ Việt Nam**.
- `units`: tổng số lượng sản phẩm đã bán
- `revenue`: tổng (số lượng × đơn giá lúc mua)

Yêu cầu:
- Cột: `brand, units, revenue`
- Sắp xếp: `revenue` giảm dần
- Kỳ vọng: **5 dòng**, dòng đầu `Samsung | 391 | 1180175000.00`

### ex07 · Khách Singapore trong tháng 9
Với **mọi** khách ở Singapore (`country = 'SG'`), đếm số đơn họ đặt trong **tháng 9/2026, giờ Việt Nam**, **kể cả khách 0 đơn** trong tháng đó.
- Cột: `id, full_name, n_orders`
- Sắp xếp: `n_orders` giảm dần; trùng thì `id` tăng dần
- Kỳ vọng: **45 dòng**

### ex08 · Đơn có hàng Samsung
Liệt kê các đơn **đã giao** đặt trong **tháng 9/2026, giờ Việt Nam**, có mua **ít nhất 1** sản phẩm brand `Samsung`. Mỗi đơn xuất hiện **đúng một lần**.
- Cột: `order_id, created_at, total_amount`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **192 dòng**

---

## 🔴 Thực tế

### ex09 · Tài khoản trùng email
> "CSKH nghi có khách tạo 2 tài khoản bằng cùng một email. Email có thể bị nhập khác nhau về **chữ hoa/thường** hoặc có **khoảng trắng thừa** ở đầu/cuối, nhưng vẫn tính là cùng một email. Liệt kê từng cặp tài khoản trùng, **mỗi cặp một lần**."

- Cột: `user_id_1, user_id_2, email` (`user_id_1` < `user_id_2`; `email` là email đã chuẩn hóa: chữ thường, bỏ khoảng trắng đầu/cuối)
- Sắp xếp: `user_id_1` tăng dần
- Kỳ vọng: **5 dòng**

### ex10 · Đối soát đơn hàng
> "Kế toán cần bảng đối soát cho các đơn có `id` từ 1685 đến 1694: giá trị đơn, số dòng hàng, và tổng tiền **đã thu thành công**. Đơn chưa thu được đồng nào thì ghi 0."

- Cột: `order_id, total_amount, n_lines, total_paid`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **10 dòng**. Gợi ý tự kiểm: với đơn thanh toán đúng 1 lần, `total_paid` bằng `total_amount`

---

## 📏 Bonus (tùy chọn, không tính điểm): anti join ở quy mô lớn
Lấy lời giải ex03. **Dự đoán trước khi đo**, viết dưới dạng comment vào `answers/ex03.sql`:
1. Trên `shop_m` (1M đơn, 100k khách), query mất khoảng bao nhiêu ms?
2. Postgres phải đọc hết bảng `orders` hay dừng sớm được? Vì sao?

Sau đó đo bằng `bench/bench.sh lessons/F05-joins/answers/ex03.sql --scales s,m`.
