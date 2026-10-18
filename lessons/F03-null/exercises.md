# F03 · Bài tập

Mỗi bài ghi rõ chạy trên **DB nào**: `shop_s` (dữ liệu chung) hoặc `lab` (bảng riêng của bài, trong schema `f03`).
Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F03-null 01`

**Pass:** 8/10 bài, dùng ≤ 2 hint.

Bảng trong `lab.f03` (xem bằng `\d f03.*`):

| Bảng | Mô tả |
|---|---|
| `f03.contacts` | Danh bạ import từ Excel. `city` có thể NULL, rỗng `''`, hoặc chỉ có khoảng trắng |
| `f03.products_import` | Sản phẩm của nhà cung cấp. `brand` NULL nghĩa là chưa xác định |
| `f03.campaigns` | Chiến dịch quảng cáo. `impressions = 0` nghĩa là chưa chạy; `clicks` NULL nghĩa là đối tác chưa gửi số liệu |
| `f03.reviews` | Đánh giá sản phẩm. `rating` NULL nghĩa là khách chỉ bình luận, không chấm sao |
| `f03.profile_changes` | Nhật ký sửa hồ sơ: giá trị cũ và mới của `phone`, `city` |

---

## 🟢 Cơ bản

### ex01 · Logic ba trị · DB `lab`
**Bước 1:** dự đoán kết quả trong chat, chưa chạy gì. **Bước 2:** viết **một** câu `SELECT` không cần bảng, trả về 1 dòng gồm 5 cột:
- `null_eq`: `NULL = NULL`
- `null_distinct`: `NULL IS DISTINCT FROM NULL`
- `and_false`: `NULL AND false`
- `or_true`: `NULL OR true`
- `not_in`: `3 NOT IN (1, 2, NULL)`

Kỳ vọng: 1 dòng. Không cho trước giá trị, vì dự đoán của bạn chính là bài tập.

### ex02 · Danh bạ hiển thị · DB `lab`
Màn hình danh bạ hiển thị thành phố của từng liên hệ. Nếu thành phố **không có thông tin**, tức là NULL, rỗng, hoặc chỉ toàn khoảng trắng, thì hiển thị `Chưa cập nhật`.
- Cột: `id, name, city_display`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **30 dòng**. Dòng 7, 9 và 11 đều hiển thị `Chưa cập nhật`

### ex03 · Không phải hàng Sony · DB `lab`
"Liệt kê mọi sản phẩm **không phải của Sony**, tính cả những sản phẩm chưa xác định brand."
- Cột: `id, name, brand`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **31 dòng**

### ex04 · 10 khách trẻ nhất · DB `shop_s`
Lấy 10 khách hàng **trẻ nhất**. Khách chưa khai ngày sinh thì không được lọt vào danh sách. Hai khách cùng ngày sinh thì xếp `id` tăng dần.
- Cột: `id, full_name, birth_date`
- Kỳ vọng: **10 dòng**, dòng đầu là `685 | Lê Gia Sơn | 2004-12-08`

---

## 🟡 Kết hợp

### ex05 · Tỉ lệ dùng mã giảm giá · DB `shop_s`
Tính trên toàn bộ bảng `orders`:
- `total_orders`: tổng số đơn
- `orders_with_code`: số đơn **có** dùng mã giảm giá
- `pct_with_code`: phần trăm đơn có dùng mã, làm tròn 2 chữ số thập phân (ví dụ `12.34`)
- Kỳ vọng: **1 dòng**, `10000 | 1479 | 14.79`

Ràng buộc: không dùng `WHERE`.

### ex06 · CTR chiến dịch · DB `lab`
CTR (%) = `clicks × 100 / impressions`, làm tròn 2 chữ số thập phân. Chiến dịch chưa chạy (`impressions = 0`) hoặc chưa có số liệu click thì để CTR **trống (NULL)**. Query **không được báo lỗi**.
- Cột: `id, name, impressions, clicks, ctr_pct`
- Sắp xếp: CTR cao nhất trước, các chiến dịch có CTR trống xếp **cuối**; trùng thì `id` tăng dần
- Kỳ vọng: **12 dòng**, dòng đầu `10 | Google Search | 30000 | 1800 | 6.00`

### ex07 · Điểm trung bình sản phẩm 2 · DB `lab`
Với sản phẩm `product_id = 2`, trả về 1 dòng:
- `n_reviews`: tổng số đánh giá
- `n_rated`: số đánh giá có chấm sao
- `avg_rated`: điểm trung bình, **chỉ tính** các đánh giá có chấm sao
- `avg_as_zero`: điểm trung bình khi coi đánh giá không chấm sao là 0 sao

Hai cột điểm trung bình làm tròn 2 chữ số thập phân. Kỳ vọng: **1 dòng**.

Trả lời thêm trong chat: *trang sản phẩm nên hiển thị cột nào, và vì sao?*

---

## 🔴 Thực tế

### ex08 · Hồ sơ nào thật sự thay đổi · DB `lab`
> "Mỗi lần khách bấm Lưu, hệ thống ghi một dòng vào `f03.profile_changes`, kể cả khi họ không sửa gì. Đội CSKH cần danh sách các lần **phone hoặc city thật sự thay đổi** để gọi xác minh. Thêm số mới vào chỗ trống, hay xóa số cũ đi, đều tính là thay đổi."

- Cột: `id, user_id, old_phone, new_phone, old_city, new_city`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **9 dòng**

### ex09 · SMS mời cập nhật ngày sinh · DB `shop_s`
> "Marketing muốn gửi SMS mời khách **ở Việt Nam** cập nhật **ngày sinh** để nhận quà sinh nhật. Chỉ gửi cho tài khoản **còn hoạt động** (chưa bị xóa), và tất nhiên khách phải **có số điện thoại**. Tin nhắn mở đầu bằng tên khách. Ai chưa có tên thì ghi `Quý khách`."

- Cột: `id, greeting_name, phone`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **207 dòng**

### ex10 · Đơn lớn không dùng VIP15 · DB `shop_s`
> "Tháng 9/2026 **theo giờ Việt Nam**, mã `VIP15` bị nghi lạm dụng. Cho mình biết **trong tháng đó** có bao nhiêu đơn **từ 10 triệu trở lên** mà **không dùng mã VIP15**, và tổng doanh thu (`total_amount`) của các đơn đó, để so sánh với nhóm có dùng VIP15."

- Cột: `orders_count, revenue`
- Kỳ vọng: **1 dòng**. Không cho trước giá trị.
