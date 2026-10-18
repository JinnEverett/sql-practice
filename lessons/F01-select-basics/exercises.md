# F01 · Bài tập

**DB: `shop_s`** cho mọi bài. Mốc thời gian tính theo **UTC**.
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F01-select-basics 01` (Claude cũng sẽ chạy khi bạn nộp).

> **Đọc hết đề.** Bài chỉ đúng khi khớp **tên cột, thứ tự cột, các dòng và thứ tự dòng**. Thiếu một vế là sai.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

---

## 🟢 Cơ bản

### ex01 · Top 10 sản phẩm đắt nhất
- Cột: `id, name, brand, price`
- Sắp xếp: giá giảm dần; cùng giá thì `id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `116 | Laptop Asus C451 | Asus | 34311000.00`

### ex02 · Khách Việt Nam đăng ký trong năm 2025
- Điều kiện: `country` là `VN`, đăng ký (`created_at`) trong năm 2025
- Cột: `id, full_name, email, created_at`
- Sắp xếp: đăng ký sớm nhất trước; trùng giờ thì `id` tăng dần
- Kỳ vọng: **299 dòng**, 3 dòng đầu là id `135, 136, 137`

### ex03 · Các thương hiệu thời trang
Danh mục 9, 10, 11, 12 là Áo nam, Áo nữ, Giày dép, Túi xách. Liệt kê **các thương hiệu khác nhau** có sản phẩm thuộc 4 danh mục này.
- Cột: `brand`
- Sắp xếp: A → Z
- Kỳ vọng: **6 dòng**, mỗi thương hiệu xuất hiện đúng 1 lần

### ex04 · Đơn bị hủy hoặc hoàn tiền có giá trị lớn
- Điều kiện: trạng thái là `cancelled` hoặc `refunded`, **và** `total_amount` từ 5 000 000 trở lên
- Cột: `id, user_id, status, total_amount`
- Sắp xếp: tổng tiền giảm dần; bằng nhau thì `id` tăng dần
- Kỳ vọng: **388 dòng**

---

## 🟡 Kết hợp

### ex05 · Áo đang bán, quy đổi ra USD
Lấy các sản phẩm **đang bán** (`is_active`) thuộc danh mục 9 hoặc 10. Thêm cột `price_usd` = giá chia 25 000, làm tròn 2 chữ số thập phân (`round(x, 2)`). **Chỉ giữ những sản phẩm có `price_usd` lớn hơn 20.**
- Cột: `id, name, price, price_usd`
- Sắp xếp: `price_usd` giảm dần; bằng nhau thì `id` tăng dần
- Kỳ vọng: **3 dòng**, dòng đầu `160 | Áo nữ Uniqlo B73C | 885000.00 | 35.40`
- Viết xong, trả lời thêm trong chat: *vì sao `ORDER BY price_usd` chạy được, nhưng `WHERE price_usd > 20` thì lỗi?*

### ex06 · Phân trang lịch sử đơn hàng
Màn hình "Đơn hàng của tôi" của user `1` hiện **5 đơn mỗi trang**, đơn mới nhất trước. Lấy **trang 3**.
- Cột: `id, created_at, status, total_amount`
- Sắp xếp: `created_at` giảm dần; trùng thì `id` giảm dần
- Kỳ vọng: **5 dòng**

### ex07 · Khách hàng ở đâu?
Liệt kê các cặp (quốc gia, thành phố) khác nhau trong bảng `users`.
- Cột: `country, city`
- Sắp xếp: `country` A→Z, rồi `city` A→Z (giữ mặc định của Postgres cho giá trị rỗng)
- Kỳ vọng: **22 dòng**
- Trả lời thêm trong chat: *nhìn kết quả, bạn thấy **2 điểm bất thường** nào về chất lượng dữ liệu?*

### ex08 · Tìm sản phẩm Sony giá mềm
Khách gõ ô tìm kiếm `sony`. Trả về các sản phẩm có **tên** chứa từ này (không phân biệt hoa/thường), **đang bán**, giá **dưới** 5 000 000.
- Cột: `id, name, price`
- Sắp xếp: giá tăng dần; bằng giá thì `id` tăng dần
- Kỳ vọng: **11 dòng**

---

## 🔴 Thực tế

### ex09 · CSKH gọi lại đơn treo
> "Bên CSKH muốn gọi lại cho các đơn **đang chờ xử lý** (`pending`) đặt trong **tháng 9/2026**, giá trị **từ 2 triệu trở lên**. Ưu tiên đơn to trước. Đơn cùng giá trị thì đơn đặt **sớm hơn** gọi trước vì khách đã chờ lâu hơn."

- Cột: `id, user_id, total_amount, created_at`
- Kỳ vọng: **29 dòng**

### ex10 · Khách hàng lâu năm
> "Marketing muốn gửi quà tri ân **10 khách hàng Việt Nam đăng ký sớm nhất**. Tất nhiên chỉ gửi cho người **còn dùng tài khoản**. Ai đã xóa tài khoản (`deleted_at` có giá trị) thì bỏ qua."

- Cột: `id, full_name, email, created_at`
- Sắp xếp: đăng ký sớm nhất trước; trùng thì `id` tăng dần
- Kỳ vọng: **10 dòng**

---

## 📏 Bonus (tùy chọn, không tính điểm)
Câu ex06 trên `shop_m` (1M đơn): lấy trang 3 của **toàn bộ** đơn hàng (bỏ điều kiện `user_id`), sắp theo `created_at DESC`. So với trang 100 000 thì sao?
Viết dự đoán vào cuối `answers/ex06.sql` dưới dạng comment, **trước khi** đo: thời gian của mỗi trang, và trang nào chậm hơn, vì sao. Sau đó ta đo bằng `bench`.
