# I05 · Bài tập (Date/time)

Tất cả chạy trên **`shop_s`**. Mỗi bài một câu lệnh vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/I05-datetime 01`.
Server chạy **UTC**. "Giờ VN" = `Asia/Ho_Chi_Minh`. Đừng dùng `now()`: dùng mốc cố định đề cho để kết quả kiểm chứng được.

**Pass:** 8/10 (9 bài chấm tự động + ex10 câu hỏi quy mô tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Lịch mua của khách số 1
Số đơn của khách `user_id = 1` **mỗi ngày** trong tháng 9/2026 (ngày giờ VN), **kể cả ngày 0 đơn**. Dùng `generate_series`.
- Cột: `ngay` (kiểu `date`), `n_orders` · Sắp xếp: `ngay`
- Kỳ vọng: **30 dòng**, dòng đầu `2026-09-01 | 1`

### ex02 · Giờ vàng
Phân bố đơn đặt trong **năm 2026 (giờ VN)** theo **giờ trong ngày giờ VN** (0–23). Đủ 24 giờ, giờ không có đơn ghi 0. `pct` = % trên tổng, làm tròn 1 chữ số.
- Cột: `gio, n_orders, pct` · Sắp xếp: `gio`
- Kỳ vọng: **24 dòng**, dòng đầu `0 | 141 | 2.4`

### ex03 · Mua lúc nửa đêm theo giờ ĐỊA PHƯƠNG
Với khách nước ngoài, múi giờ theo quốc gia: SG `Asia/Singapore`, KR `Asia/Seoul`, AU `Australia/Sydney`, TH `Asia/Bangkok`, JP `Asia/Tokyo`, US `America/Los_Angeles`. Với mỗi quốc gia: tổng số đơn, số đơn đặt **từ 0h đến trước 6h giờ địa phương của khách**, và số đơn từ 0h đến trước 6h **nếu (sai lầm) tính theo giờ VN**.
- Cột: `country, n_orders, n_night_local, n_night_vn` · Sắp xếp: `country`
- Kỳ vọng: **6 dòng**, dòng đầu `AU | 400 | 85 | 56`

---

## 🟡 Kết hợp

### ex04 · Doanh thu theo tuần ISO
Quý 3/2026 (giờ VN), đơn không `cancelled`/`refunded`. Gom theo **tuần ISO** (tuần bắt đầu thứ Hai, theo giờ VN). Tuần đầu tiên có thể bắt đầu từ cuối tháng 6: vẫn chỉ tính các đơn trong quý.
- Cột: `tuan` (dạng `2026-W27`), `thu_hai` (ngày thứ Hai đầu tuần, kiểu `date`), `n_orders, revenue` · Sắp xếp: `thu_hai`
- Kỳ vọng: **14 dòng**, dòng đầu `2026-W27 | 2026-06-29 | 106 | 825409000.00`

### ex05 · Đơn treo quá 3 ngày
Tính tại mốc `2026-10-01 00:00` giờ VN: các đơn đang `pending` hoặc `paid` được đặt **trước mốc đó hơn 3 ngày**. `waited` = thời gian đã chờ, **cắt bỏ phần dưới giờ** rồi biểu diễn dạng ngày + giờ (`657 days 01:00:00`).
- Cột: `id, status, created_at, waited` · Sắp xếp: `created_at`, `id`
- Kỳ vọng: **72 dòng**, dòng đầu `589 | pending | … | 657 days 01:00:00`

### ex06 · Lưới khách × tháng
Với các khách `id` từ 21 đến 25 và các tháng 01–06/2026 (giờ VN): số đơn của khách trong tháng (mọi trạng thái), **đủ 30 ô**, ô không có đơn ghi 0.
- Cột: `user_id, thang` (`YYYY-MM`), `n_orders` · Sắp xếp: `user_id`, `thang`
- Kỳ vọng: **30 dòng**, dòng đầu `21 | 2026-01 | 2`

---

## 🔴 Thực tế

### ex07 · SLA thanh toán 15 phút
Xét các đơn đặt trong tháng 9/2026 (giờ VN). Một đơn "đạt SLA" nếu **lần thanh toán thành công đầu tiên** xảy ra **không quá 15 phút** sau khi đặt đơn. Một đơn có thể có nhiều payment (thất bại, hoặc bị trừ tiền 2 lần). Gom theo **phương thức của lần thanh toán thành công đầu tiên**; đơn chưa có thanh toán thành công vào nhóm `'(chưa thanh toán)'`.
- Cột: `method, n_orders, n_within_15m, pct` (pct làm tròn 1 chữ số) · Sắp xếp: `method`
- Kỳ vọng: **5 dòng**, dòng đầu `bank_transfer | 163 | 75 | 46.0`

### ex08 · Bao lâu thì khách mua đơn đầu?
Khách **đăng ký trong năm 2025** (giờ VN), gom theo tháng đăng ký: số khách đã mua (`n_users`), số khách chưa từng có đơn (`n_never`), và **số ngày trung bình** từ lúc đăng ký tới đơn đầu tiên (mọi trạng thái, tính bằng ngày thập phân, làm tròn 1 chữ số). Dữ liệu có lỗi: vài khách có đơn **trước** thời điểm đăng ký. Bỏ những khách đó khỏi `n_users` và trung bình.
- Cột: `thang_dk, n_users, n_never, avg_days` · Sắp xếp: `thang_dk`
- Kỳ vọng: **12 dòng**, dòng đầu `2025-01 | 23 | 0 | 55.1`

### ex09 · Ngày xử lý đơn
Kho chỉ làm việc **thứ Hai đến thứ Sáu**, nghỉ lễ **01/09/2026** và **02/09/2026**. Đơn đặt vào ngày làm việc thì xử lý ngay trong ngày (giờ VN). Đơn đặt vào ngày nghỉ thì xử lý vào **ngày làm việc kế tiếp**. Tính cho các đơn đặt từ 28/08 đến hết 03/09/2026 (giờ VN) có `id` chia hết cho 5. `thu` = isodow của ngày đặt.
- Cột: `id, ngay_dat, thu, ngay_xu_ly` · Sắp xếp: `id`
- Kỳ vọng: **43 dòng**, dòng đầu `8705 | 2026-08-28 | 5 | 2026-08-28`. Đơn đặt 01/09 xử lý **03/09**.

---

## 📏 ex10 · Câu hỏi quy mô: lọc theo ngày ở 10 triệu đơn
```sql
-- A
SELECT count(*) FROM orders WHERE (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = date '2026-09-15';
-- B
SELECT count(*) FROM orders WHERE created_at >= '2026-09-15 00:00+07' AND created_at < '2026-09-16 00:00+07';
```
1. **Dự đoán** (ghi vào `answers/ex10.md`): ở `s`, `m`, `l`, không có index, câu nào nhanh hơn và vì sao? Sau khi có index trên `created_at` thì sao?
2. Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` trên từng DB. Thử index trong transaction:
   `BEGIN; CREATE INDEX ON orders (created_at); EXPLAIN (ANALYZE, BUFFERS) <A>; EXPLAIN (ANALYZE, BUFFERS) <B>; ROLLBACK;`
3. Rút ra quy tắc viết điều kiện thời gian.

Lời giải và số đo thật: `solutions/ex10.md`.
