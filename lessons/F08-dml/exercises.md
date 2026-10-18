# F08 · Bài tập

Tất cả chạy trên DB **`lab`**, schema **`f08`**. Mỗi bài **bắt đầu từ trạng thái vừa chạy `setup.sql`**: script chấm tự reset trước mỗi bài, nên các bài **không ảnh hưởng nhau**.
Khi thử tay trong psql: chạy lại `setup.sql` cho sạch, hoặc bọc trong `BEGIN; … ROLLBACK;`.

```bash
# reset dữ liệu về ban đầu
MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d lab -X -q < lessons/F08-dml/setup.sql
# tự chấm bài NN (tự reset, chạy bài làm trong transaction rồi ROLLBACK)
bash lessons/F08-dml/check.sh 03
```
Mỗi bài viết **một câu lệnh DML** vào `answers/exNN.sql`, hoặc dán vào chat.
Mọi mốc thời gian có múi giờ: dùng `+07` hoặc `AT TIME ZONE 'Asia/Ho_Chi_Minh'` (đừng để phụ thuộc TimeZone của session).

**Pass:** 8/10 bài, dùng ≤ 2 hint.

Bảng dùng trong bài: `products(id, sku, name, price, stock, is_active, updated_at)` (8 dòng), `stock_feed(sku, name, qty, price, received_at)`, `cart_items`, `subscribers`, `newsletter`, `daily_stats`, `new_orders`, `orders`. Xem cột bằng `\d f08.<bảng>`.

---

## 🟢 Cơ bản

### ex01 · Nhập hai sản phẩm mới
Thêm **hai** sản phẩm bằng **một** câu `INSERT`: `P-011` "Đế tản nhiệt" giá 150000 tồn 30; `P-012` "Pad chuột" giá 60000 tồn 0. Bảng phải **tự sinh `id`** (đừng tự điền `id`) và `is_active` để mặc định. Câu lệnh phải **trả về** `id` và `sku` của hai dòng vừa chèn.
- Output của câu lệnh: `id, sku`
- Kỳ vọng: **2 dòng**, `9 | P-011` và `10 | P-012`

### ex02 · Nạp sản phẩm mới từ feed
`stock_feed` là file nhà cung cấp gửi. Hãy thêm vào `products` **những sản phẩm có trong feed mà chưa có** (so theo `sku`). Lấy `name`, `price` từ feed, `stock` = `qty`. Một `sku` có thể xuất hiện nhiều lần trong feed: lấy **bản nhận mới nhất** (`received_at`). Mỗi `sku` chỉ chèn **một** dòng.
- Kỳ vọng: `products` có **10 dòng**; `P-009` (520000, tồn 30) và `P-010` (310000, tồn 20)

### ex03 · Tăng giá 10% cho hàng rẻ
Tăng giá **10%** (làm tròn về số nguyên) cho các sản phẩm **đang bán** (`is_active`) có giá **dưới 500000**, và cập nhật `updated_at` về **thời điểm hiện tại** cho đúng các dòng đó.
- Kỳ vọng: **4 dòng** bị sửa. `P-001` thành 275000, `P-003` thành 495000, `P-006` thành 99000, `P-008` thành 385000. `P-007` (ngừng bán, giá 180000) **giữ nguyên**

---

## 🟡 Kết hợp

### ex04 · Cập nhật tồn kho và giá theo feed
Với các sản phẩm **đã có** trong `products`, cập nhật `stock` = `qty` và `price` từ **bản nhận mới nhất** của sku đó trong feed, đồng thời `updated_at = now()`. Nếu feed ghi `price` là **NULL** thì **giữ giá cũ**. Sản phẩm không có trong feed thì **không đụng tới**.
- Kỳ vọng: **5 dòng** bị sửa (`P-001`, `P-002`, `P-003`, `P-004`, `P-006`). `P-002` phải ra tồn **10**, giá **950000**; `P-004` tồn **0**, giá **giữ 600000**

### ex05 · Dọn giỏ hàng
Xóa khỏi `cart_items` mọi dòng mà sản phẩm **ngừng bán** (`is_active = false`) **hoặc hết hàng** (`stock = 0`).
- Kỳ vọng: **4 dòng** bị xóa, `cart_items` còn **5 dòng**

### ex06 · Xóa email đăng ký trùng
`subscribers` có nhiều dòng thực chất là **cùng một email** (khác hoa/thường hoặc dư khoảng trắng đầu/cuối). Hai email coi là trùng nếu `lower(trim(email))` giống nhau. Với mỗi nhóm trùng, **giữ bản có `created_at` sớm nhất**; hòa thì giữ **`id` nhỏ nhất**; xóa các bản còn lại.
- Kỳ vọng: **4 dòng** bị xóa, còn lại `id` = 1, 3, 6, 8

### ex07 · Cộng dồn doanh thu theo ngày
`new_orders` là các đơn mới về. `daily_stats(day, orders, revenue)` là thống kê theo **ngày giờ Việt Nam**. Hãy cộng dồn các đơn mới vào `daily_stats`: ngày **đã có** thì **cộng thêm** `orders` và `revenue`; ngày **chưa có** thì chèn mới. Làm bằng **một** câu lệnh.
- Kỳ vọng: `daily_stats` có **4 dòng**: `10-13 | 11 | 5100000`, `10-14 | 10 | 5000000`, `10-15 | 2 | 900000`, `10-16 | 1 | 900000`

### ex08 · Thêm email vào newsletter
Thêm vào `newsletter` danh sách sau, **bỏ qua email đã có** và **không báo lỗi** nếu danh sách tự trùng: `an@x.vn`, `dung@x.vn`, `binh@x.vn`, `emi@x.vn`, `dung@x.vn`. Câu lệnh phải **trả về đúng các email thực sự được thêm mới**.
- Output của câu lệnh: `email`
- Kỳ vọng: **2 dòng**: `dung@x.vn`, `emi@x.vn`; `newsletter` còn **4 dòng**

---

## 🔴 Thực tế

### ex09 · Đồng bộ kho hằng đêm
Mỗi đêm bộ phận kho muốn đồng bộ `products` theo `stock_feed` bằng **một** câu `MERGE`, dựa trên **bản nhận mới nhất** của từng `sku` trong feed:
- sku **có trong feed, đã có** trong `products`, và `qty = 0`: **ngừng bán** (`is_active = false`, `stock = 0`), giá giữ nguyên;
- sku **có trong feed, đã có**, `qty > 0`: cập nhật `stock = qty`, giá lấy từ feed (**NULL thì giữ giá cũ**), `is_active = true`;
- sku **có trong feed, chưa có** trong `products`: **thêm mới** (`name`, `price`, `stock = qty`);
- sku **có trong `products` mà không có trong feed**: **không đụng tới**;
- mọi dòng bị sửa: `updated_at = now()`.
- Kỳ vọng: `products` có **10 dòng**. `P-004` (hết hàng): `is_active = false`, tồn 0, giá 600000. `P-005`, `P-007`, `P-008` **không đổi**. `P-009`, `P-010` được thêm

### ex10 · Job hủy đơn quá hạn
Hệ thống có job chạy định kỳ: đơn **`pending`** được đặt **trước `2026-10-10 00:00` giờ Việt Nam** (đúng mốc này **chưa** tính là quá hạn) thì chuyển `status = 'cancelled'` và `cancelled_at = now()`. Đơn ở trạng thái khác **không được đụng tới**. Câu lệnh phải **trả về** `id` và `user_id` của các đơn vừa bị hủy để gửi thông báo.
Sau khi viết xong, trả lời **bằng comment cuối file** `answers/ex10.sql`: nếu job **chạy lại lần 2** ngay sau đó thì trả về mấy dòng, và **vì sao** điều này quan trọng với một job chạy định kỳ?
- Output của câu lệnh: `id, user_id`
- Kỳ vọng: **3 dòng**: `1 | 10`, `4 | 13`, `5 | 10`. Đơn `7` (đúng 00:00 ngày 10) giữ `pending`

---

## 📏 Bonus (tùy chọn, không tính điểm): `UPDATE` cả bảng ở 1 triệu dòng
Trên DB `lab` tạo bảng thử rồi **dự đoán trước** (ghi vào comment): sau khi `UPDATE` **mọi** dòng một lần, kích thước bảng (`pg_relation_size`) tăng bao nhiêu? Và nếu `UPDATE` thêm lần nữa?
```sql
CREATE TABLE f08.big AS SELECT g AS id, 0 AS n FROM generate_series(1, 1000000) g;
SELECT pg_size_pretty(pg_relation_size('f08.big'));      -- trước
UPDATE f08.big SET n = n + 1;
SELECT pg_size_pretty(pg_relation_size('f08.big'));      -- sau lần 1
```
(`setup.sql` sẽ xóa bảng `f08.big` khi bạn chạy lại.) Đây là mở đầu cho P07 (MVCC & VACUUM).
