# F04 · Bài tập

Tất cả các bài chạy trên **`shop_s`**. Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F04-aggregates 01`

**Pass:** 8/10 bài, dùng ≤ 2 hint.

---

## 🟢 Cơ bản

### ex01 · Đơn theo trạng thái
Mỗi trạng thái đơn hàng có bao nhiêu đơn?
- Cột: `status, n_orders`
- Sắp xếp: `n_orders` giảm dần
- Kỳ vọng: **6 dòng**, dòng đầu `delivered | 8457`

### ex02 · Khách theo quốc gia
Với mỗi quốc gia, tính:
- `n_users`: số khách
- `n_with_city`: số khách đã điền thành phố
- `n_deleted`: số khách đã xóa tài khoản

Yêu cầu:
- Cột: `country, n_users, n_with_city, n_deleted`
- Sắp xếp: `n_users` giảm dần; trùng thì `country` tăng dần
- Kỳ vọng: **7 dòng**, dòng đầu `VN | 762 | 732 | 20`
- Ràng buộc: **không dùng `WHERE`, không dùng `FILTER`**

### ex03 · Danh mục đông sản phẩm
Tìm các danh mục (`category_id`) có **từ 8 sản phẩm đang bán trở lên**. Với mỗi danh mục, cho biết số sản phẩm đang bán, giá thấp nhất và giá cao nhất **trong số các sản phẩm đang bán**.
- Cột: `category_id, n_active, min_price, max_price`
- Sắp xếp: `category_id` tăng dần
- Kỳ vọng: **6 dòng**, dòng đầu `13 | 10 | 3018000.00 | 27765000.00`

### ex04 · Tỉ lệ thanh toán thành công
Với mỗi phương thức thanh toán, tính:
- `n_payments`: tổng số giao dịch
- `n_succeeded`: số giao dịch thành công
- `success_rate`: tỉ lệ thành công (%), làm tròn 2 chữ số thập phân

Yêu cầu:
- Cột: `method, n_payments, n_succeeded, success_rate`
- Sắp xếp: tỉ lệ cao nhất trước; trùng thì `method` tăng dần
- Kỳ vọng: **4 dòng**, dòng đầu `bank_transfer | 1539 | 1366 | 88.76`

---

## 🟡 Kết hợp

### ex05 · Hành vi theo loại sự kiện
Với mỗi loại sự kiện trong `events`, tính:
- `n_events`: số sự kiện
- `n_logged_in_events`: số sự kiện do khách **đã đăng nhập** tạo ra
- `n_users`: số **khách đăng nhập khác nhau** đã tạo ra loại sự kiện đó

Yêu cầu:
- Cột: `event_type, n_events, n_logged_in_events, n_users`
- Sắp xếp: `event_type` tăng dần
- Kỳ vọng: **5 dòng**, dòng đầu `add_to_cart | 5562 | 3821 | 847`

### ex06 · Doanh thu theo tháng 2026
> "Kế toán cần doanh thu **từng tháng** của 9 tháng đầu năm 2026, **tính theo giờ Việt Nam**. Không tính đơn đã **hủy** hoặc **hoàn tiền**."

- Cột: `month` (kiểu `date`, là ngày đầu tháng, ví dụ `2026-01-01`), `n_orders`, `revenue` (tổng `total_amount`)
- Sắp xếp: `month` tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01-01 | 355 | 2203041000.00`

### ex07 · Báo cáo mã giảm giá
> "Thống kê theo từng mã giảm giá: số đơn, tiền giảm trung bình mỗi đơn, tổng tiền đã giảm. Đơn **không dùng mã** gom thành một dòng riêng, ghi là `(không mã)`."

- Cột: `code_label, n_orders, avg_discount` (làm tròn đến đồng), `total_discount`
- Sắp xếp: `n_orders` giảm dần
- Kỳ vọng: **5 dòng**

### ex08 · Tóm tắt đơn hàng
Với các đơn có `id` từ 1 đến 10, tóm tắt từ `order_items`:
- `n_lines`: số dòng hàng
- `total_qty`: tổng số lượng sản phẩm
- `product_ids`: danh sách `product_id` theo **đúng thứ tự dòng hàng** (`line_no`), ngăn cách bằng dấu phẩy, không có khoảng trắng, ví dụ `39,100,28,159`

Yêu cầu:
- Cột: `order_id, n_lines, total_qty, product_ids`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **10 dòng**

---

## 🔴 Thực tế

### ex09 · Khách VIP năm 2025
> "Chương trình tri ân năm 2025: chọn khách có **từ 20 đơn giao thành công** (`delivered`) trở lên **trong năm 2025, tính theo giờ Việt Nam**, và tổng giá trị các đơn đó **từ 150 triệu trở lên**. Người chi nhiều nhất đứng đầu."

- Cột: `user_id, n_orders, total_spent`
- Kỳ vọng: **12 dòng**

### ex10 · Nghi trừ tiền hai lần
> "Có khách phàn nàn bị trừ tiền 2 lần cho 1 đơn. Lấy danh sách các đơn có **từ 2 lần thanh toán thành công** trở lên. Lưu ý: thanh toán thất bại rồi thử lại là chuyện bình thường, không tính."

- Cột: `order_id, n_succeeded, total_paid` (tổng tiền của các lần thanh toán thành công)
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **9 dòng**

---

## 📏 Bonus (tùy chọn, không tính điểm): GROUP BY ở quy mô lớn
Lấy lời giải ex06. Trên `shop_s` (10k đơn) query chạy chưa tới 10 ms. **Dự đoán trước khi đo**, viết dưới dạng comment vào `answers/ex06.sql`:
1. Trên `shop_m` (1M đơn), query mất khoảng bao nhiêu ms?
2. Postgres phải đọc **bao nhiêu dòng** để trả về 9 dòng kết quả? Vì sao?

Sau đó đo bằng `bench/bench.sh lessons/F04-aggregates/answers/ex06.sql --scales s,m`.
