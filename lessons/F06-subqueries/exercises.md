# F06 · Bài tập

Tất cả các bài chạy trên **`shop_s`**. Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F06-subqueries 01`. Dòng `Cột:` sẽ báo ngay nếu tên cột lệch đề.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

> Module này luyện **subquery**. Bài nào ghi "không dùng JOIN" thì phải giải bằng subquery, dù JOIN cũng ra cùng kết quả.

---

## 🟢 Cơ bản

### ex01 · Sản phẩm đắt hơn mặt bằng chung
Liệt kê các sản phẩm **đang bán** có giá cao hơn giá trung bình của **mọi sản phẩm đang bán**.
- Cột: `id, name, price`
- Sắp xếp: `price` giảm dần; trùng thì `id` tăng dần
- Kỳ vọng: **31 dòng**, dòng đầu `116 | Laptop Asus C451 | 34311000.00`

### ex02 · So với đơn trung bình
Với các đơn có `id` từ 5001 đến 5010, cho biết giá trị đơn, giá trị trung bình của **mọi đơn** trong hệ thống, và chênh lệch giữa hai số đó.
- Cột: `order_id, total_amount, avg_all, diff`
  - `avg_all`: trung bình `total_amount` của mọi đơn, làm tròn 2 chữ số
  - `diff` = `total_amount − avg_all` (dùng `avg_all` đã làm tròn)
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `5001 | 435000.00 | 6832435.60 | -6397435.60`

### ex03 · Khách từng mua Apple
Liệt kê các khách từng đặt ít nhất một đơn (trạng thái bất kỳ) có sản phẩm brand `Apple`. **Không dùng JOIN**, chỉ dùng `IN`.
- Cột: `id, full_name`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **306 dòng**

### ex04 · Đơn từng bị thanh toán lỗi
Liệt kê các đơn **đã giao** đặt trong **tháng 9/2026, giờ Việt Nam**, có **ít nhất một** lần thanh toán thất bại (`failed`). Dùng `EXISTS`.
- Cột: `order_id, created_at, total_amount`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **56 dòng**

---

## 🟡 Kết hợp

### ex05 · Khách "tàng hình"
Tìm các khách **chưa từng phát sinh event nào** khi đăng nhập (không có dòng nào trong `events` mang `user_id` của họ).
- Cột: `id, full_name, created_at`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu là khách `476`

### ex06 · Đắt hơn trung bình danh mục
Liệt kê các sản phẩm **đang bán** có giá cao hơn giá trung bình của các sản phẩm **đang bán** **trong cùng danh mục** với nó.
- Cột: `id, name, category_id, price, category_avg` (`category_avg` làm tròn **0** chữ số)
- Sắp xếp: `category_id` tăng dần, rồi `price` giảm dần, rồi `id` tăng dần
- Kỳ vọng: **82 dòng**, dòng đầu `189 | Áo nam Biti's A255 | 9 | 590000.00 | 354600`

### ex07 · Danh mục lá
Danh mục **lá** là danh mục **không phải cha** của danh mục nào khác. Liệt kê mọi danh mục lá kèm số sản phẩm **đang bán** thuộc trực tiếp danh mục đó (kể cả danh mục 0 sản phẩm).
- Cột: `id, name, n_active_products`
- Sắp xếp: `n_active_products` giảm dần; trùng thì `id` tăng dần
- Kỳ vọng: **28 dòng**, dòng đầu `13 | Điện thoại | 10`

### ex08 · Khách "cá voi"
> "Ban giám đốc muốn biết khách nào chi tiêu vượt trội: tổng giá trị các đơn **đã giao** của khách đó lớn hơn **10 lần** mức chi tiêu trung bình **của một khách**."

Mức chi tiêu trung bình của một khách = trung bình của tổng chi tiêu (đơn đã giao) **trên mỗi khách**, chỉ tính các khách có ít nhất 1 đơn đã giao.
- Cột: `user_id, full_name, total_spent`
- Sắp xếp: `total_spent` giảm dần; trùng thì `user_id` tăng dần
- Kỳ vọng: **8 dòng**, dòng đầu `1 | Huỳnh Đức Ngọc | 5884970000.00`

---

## 🔴 Thực tế

### ex09 · Khách rời bỏ
> "Marketing muốn gửi voucher win-back cho khách **có ít nhất một đơn đã giao trong tháng 8/2026** nhưng **không đặt đơn nào trong tháng 9/2026**. Đơn đã **hủy** (`cancelled`) trong tháng 9 không tính là đã đặt, vì khách đặt rồi bỏ thì vẫn là khách cần kéo lại. Bỏ qua các tài khoản **đã xóa**. Mốc tháng tính theo **giờ Việt Nam**."

- Cột: `id, full_name, email`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **203 dòng**

### ex10 · Đơn thu lệch tiền
> "Kế toán cần danh sách các đơn đặt trong **tháng 9/2026 (giờ Việt Nam)**, **trừ** đơn đã hủy (`cancelled`) và đã hoàn tiền (`refunded`), mà tổng tiền **đã thu thành công** **khác** giá trị đơn, gồm thu thiếu, thu thừa, và **chưa thu đồng nào**."

**Không dùng JOIN**: tính `total_paid` bằng subquery.
- Cột: `order_id, total_amount, total_paid, diff` (`diff` = `total_paid − total_amount`: âm là thu thiếu, dương là thu thừa)
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **62 dòng**

---

## 📏 Bonus (tùy chọn, không tính điểm): `NOT IN` vs `NOT EXISTS` ở quy mô lớn
Viết ex05 theo **hai cách**: `NOT EXISTS`, và `NOT IN` (đã xử lý NULL để ra đúng 9 dòng trên `shop_s`).

**Dự đoán trước khi đo**, viết dưới dạng comment vào `answers/ex05.sql`:
1. Trên `shop_m` (100k khách, khoảng 3M event), mỗi cách mất khoảng bao lâu?
2. Hai cách có chạy nhanh như nhau không? Nếu không, cách nào chậm hơn, và chậm hơn khoảng bao nhiêu lần?

Coach sẽ đo cùng bạn (có đặt `statement_timeout` để không treo máy).
