# F10 · Bài tập

Tất cả chạy trên **`shop_s`**. Mỗi bài viết **một câu `SELECT`** vào `answers/exNN.sql`.
Tự chấm: `bash tools/check.sh lessons/F10-expressions 01`. Dòng `Cột:` báo ngay nếu tên cột lệch đề.
Mốc thời gian có múi giờ: dùng `+07` hoặc `AT TIME ZONE 'Asia/Ho_Chi_Minh'`. Server chạy UTC.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

---

## 🟢 Cơ bản

### ex01 · Phân khúc giá
Chia các sản phẩm **đang bán** thành 4 phân khúc theo giá: dưới 100 000 là `'bình dân'`; từ 100 000 đến dưới 1 000 000 là `'trung cấp'`; từ 1 000 000 đến dưới 10 000 000 là `'cao cấp'`; còn lại là `'xa xỉ'`. Đếm số sản phẩm mỗi phân khúc.
- Cột: `segment, n_products`
- Sắp xếp: theo **thứ tự giá** của phân khúc (bình dân → xa xỉ), **không** theo chữ cái
- Kỳ vọng: **4 dòng**, dòng đầu `bình dân | 28`

### ex02 · Chuẩn hóa tên thành phố
Với khách ở Việt Nam (`country = 'VN'`), TP.HCM đang được ghi nhiều kiểu: `TP. Hồ Chí Minh`, `TP.HCM`, `HCM`, `Ho Chi Minh`. Gộp hết về `'TP. Hồ Chí Minh'`. Các thành phố khác giữ nguyên tên. Khách không có thành phố ghi là `'(không rõ)'`. Đếm số khách mỗi thành phố.
- Cột: `city_norm, n_users`
- Sắp xếp: `n_users` giảm dần, trùng thì `city_norm` tăng dần
- Kỳ vọng: **8 dòng**, dòng thứ hai `TP. Hồ Chí Minh | 190`

### ex03 · Hiển thị sản phẩm
Với các sản phẩm có `id ≤ 10`, **cộng với** mọi sản phẩm có tên thừa khoảng trắng ở đầu hoặc cuối, tạo:
- `code`: chữ `P` + phần số của `sku` **bỏ các số 0 ở đầu** (`SKU-000007` → `P7`);
- `title`: brand **viết hoa toàn bộ** + `' · '` + tên sản phẩm **đã bỏ khoảng trắng thừa** hai đầu;
- `n_extra_spaces`: số khoảng trắng thừa đã bỏ.
- Cột: `id, code, title, n_extra_spaces`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **11 dòng**, dòng đầu `1 | P1 | SAMSUNG · Ốp lưng Samsung C4CA | 0`

### ex04 · Tên miền email
Thống kê khách theo **tên miền email** (phần sau `@`). Email có thể bị viết hoa hoặc thừa khoảng trắng, nên `YAHOO.COM` và `yahoo.com` là một. `pct` là phần trăm trên **tổng số khách**, làm tròn 1 chữ số.
- Cột: `domain, n_users, pct`
- Sắp xếp: `n_users` giảm dần, trùng thì `domain` tăng dần
- Kỳ vọng: **5 dòng**, dòng đầu `gmail.com | 503 | 50.3`

---

## 🟡 Kết hợp

### ex05 · Nhóm tuổi
Tính **tuổi tròn** của khách **chưa bị xóa** (`deleted_at IS NULL`) tại ngày `2026-10-01`. Người chưa tới sinh nhật trong năm 2026 thì chưa được cộng tuổi. Chia nhóm: `'<18'`, `'18-24'`, `'25-34'`, `'35-44'`, `'45+'`. Khách không có ngày sinh vào nhóm `'(không rõ)'`. Chỉ liệt kê nhóm có khách.
- Cột: `age_group, n_users`
- Sắp xếp: nhóm trẻ trước, `(không rõ)` cuối cùng
- Kỳ vọng: **5 dòng**, dòng đầu `18-24 | 45`

### ex06 · Báo cáo tháng năm 2026
Kế toán cần báo cáo **mỗi tháng năm 2026 theo giờ Việt Nam**: số đơn và doanh thu. Không tính đơn `cancelled` và `refunded`. Doanh thu là tổng `total_amount`, hiển thị dạng `2.203.041.000 ₫` (dấu chấm phân cách nghìn, không có phần lẻ, một khoảng trắng rồi `₫`). Tháng hiển thị dạng `MM/YYYY`.
- Cột: `thang, n_orders, doanh_thu`
- Sắp xếp: theo thời gian tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu `01/2026 | 355 | 2.203.041.000 ₫`

### ex07 · Khách hay mua vào thứ mấy?
Xét mọi đơn đặt trong **quý 3/2026 giờ Việt Nam** (tháng 7–9). Đếm số đơn theo **thứ trong tuần (giờ VN)**, kèm tỉ lệ phần trăm trên tổng số đơn của quý, làm tròn 1 chữ số. Nhãn: `'Thứ 2'` … `'Thứ 7'`, `'Chủ nhật'`.
- Cột: `thu, n_orders, pct`
- Sắp xếp: Thứ 2 → Chủ nhật
- Kỳ vọng: **7 dòng**, dòng đầu `Thứ 2 | 392 | 13.7`

### ex08 · Sinh nhật tuần tới
CSKH muốn gửi quà cho khách **chưa bị xóa** có sinh nhật từ **19/10 đến 25/10** (không quan tâm năm sinh). `tuoi_moi` là số tuổi khách sẽ tròn trong lần sinh nhật năm 2026. Câu query phải chạy đúng với **mọi** ngày sinh có thể có, kể cả 29/02.
- Cột: `id, full_name, birth_date, tuoi_moi`
- Sắp xếp: theo ngày-tháng sinh tăng dần, trùng thì `id` tăng dần
- Kỳ vọng: **6 dòng**, dòng đầu `551 | Đỗ Anh Nam | 1996-10-19 | 30`

---

## 🔴 Thực tế

### ex09 · Phân hạng khách hàng
Marketing phân hạng khách **chưa bị xóa** có **ít nhất một đơn `delivered`**, chỉ dựa trên các đơn `delivered`, tính tại mốc `2026-10-01` giờ VN:
- `recency_days` = số ngày từ **ngày (giờ VN)** của đơn delivered gần nhất tới ngày `2026-10-01`;
- `frequency` = số đơn delivered; `monetary` = tổng `total_amount` của các đơn đó.

Xét theo **thứ tự ưu tiên**, khách thỏa điều kiện nào trước thì vào hạng đó:
1. `monetary` ≥ 50 000 000 **và** `recency_days` ≤ 90 → `'VIP'`
2. `frequency` ≥ 5 → `'Trung thành'`
3. `recency_days` > 180 → `'Ngủ đông'`
4. còn lại → `'Thường'`

Mỗi hạng cho biết số khách và `monetary` trung bình (làm tròn về số nguyên).
- Cột: `segment, n_users, avg_monetary`
- Sắp xếp: VIP, Trung thành, Ngủ đông, Thường
- Kỳ vọng: **4 dòng**, dòng đầu `VIP | 250 | 161056124`

### ex10 · Phiếu đơn hàng che thông tin cá nhân
In phiếu cho các đơn `id` từ 146 đến 155:
- `order_code`: `'DH'` + ngày đặt **giờ VN** dạng `YYMMDD` + `'-'` + `id` đệm số 0 bên trái cho đủ 6 chữ số. Ví dụ đơn 146 đặt lúc `2024-08-27 23:11 UTC`, tức sáng 28/08 giờ VN, nên mã là `DH240828-000146`;
- `customer`: tên khách, thiếu tên thì `'(ẩn danh)'`;
- `phone_masked`: số điện thoại đưa về dạng `0…` (số `+84 954511385` là `0954511385`), rồi giữ **3 số đầu và 3 số cuối**, giữa thay bằng `****`: `095****385`. Không có số thì `'(không có)'`;
- `email_masked`: email chuẩn hóa chữ thường, bỏ khoảng trắng, giữ **ký tự đầu** + `***@` + tên miền: `b***@yahoo.com`.
- Cột: `order_code, customer, phone_masked, email_masked`
- Sắp xếp: theo `id` đơn tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `DH240828-000146 | Huỳnh Đức Ngọc | (không có) | n***@fpt.com.vn`

---

## 📏 Bonus (tùy chọn): ex08 trên dữ liệu lớn
1. Chạy câu của bạn ở ex08 trên `shop_m` (100k khách). Nếu bạn dùng `make_date(2026, extract(month …), extract(day …))` thì chuyện gì xảy ra? Vì sao `shop_s` không lộ lỗi này?
2. **Dự đoán trước** rồi đo: ex06 trên `shop_m` và `shop_l` mất bao lâu? Thời gian tăng tuyến tính theo số đơn không?
   `bench/bench.sh lessons/F10-expressions/answers/ex06.sql --scales s,m,l --runs 1`
Lời giải: `solutions/ex11.md`.
