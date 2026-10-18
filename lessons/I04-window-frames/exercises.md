# I04 · Bài tập (Window II: LAG/LEAD, frame)

Bài 1–8 chạy trên **`shop_s`**, bài 9 trên DB **`lab`** schema `i04` (script chấm tự chạy `setup.sql`).
Mỗi bài một câu lệnh vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/I04-window-frames 01`.

**Pass:** 8/10 (9 bài chấm tự động + ex10 câu hỏi quy mô tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Doanh thu lũy kế tháng 9
Doanh thu ngày (giờ VN) = tổng `total_amount` đơn **không** `cancelled`/`refunded`, trong tháng 9/2026. Thêm cột doanh thu **cộng dồn từ đầu tháng**.
- Cột: `ngay, revenue, cum_revenue` · Sắp xếp: `ngay`
- Kỳ vọng: **30 dòng**, dòng đầu `2026-09-01 | 74415000.00 | 74415000.00`

### ex02 · Khoảng cách giữa các đơn
Mọi đơn của khách `user_id = 25` (mọi trạng thái): số ngày kể từ **đơn liền trước** của khách, làm tròn 1 chữ số (đơn đầu tiên để NULL).
- Cột: `id, created_at, days_since_prev` · Sắp xếp: `created_at`, `id`
- Kỳ vọng: **43 dòng**, dòng thứ hai `159 | … | 94.4`

### ex03 · Trung bình trượt 7 ngày
Với mỗi ngày tháng 9/2026: doanh thu ngày (như ex01) và **trung bình 7 ngày gần nhất tính cả hôm đó** (`ma7`, làm tròn về số nguyên). Ngày 01/09 phải dùng cả doanh thu 26–31/08.
- Cột: `ngay, revenue, ma7` · Sắp xếp: `ngay`
- Kỳ vọng: **30 dòng**, dòng đầu `2026-09-01 | 74415000.00 | 145257000`

---

## 🟡 Kết hợp

### ex04 · Đơn đầu, đơn cuối, đơn lớn nhất trong tháng
Các đơn của khách `user_id = 1` đặt trong tháng 9/2026 (giờ VN). Mỗi dòng kèm `id` của đơn **đầu tiên** và **cuối cùng** trong tháng (theo thời gian), và `total_amount` lớn nhất trong tháng.
- Cột: `id, created_at, total_amount, first_order_id, last_order_id, max_total` · Sắp xếp: `created_at`, `id`
- Kỳ vọng: **51 dòng**, mọi dòng có `first_order_id = 8850`, `last_order_id = 9944`

### ex05 · Lũy kế theo ngày (RANGE và ROWS)
Các đơn đặt từ 01/09 đến hết 03/09/2026 (giờ VN). Mỗi đơn kèm `ngay` (giờ VN) và `cum_orders` = **số đơn tính từ đầu khoảng tới hết ngày của đơn đó**. Hai đơn cùng ngày phải có cùng `cum_orders`.
- Cột: `id, ngay, cum_orders` · Sắp xếp: `id`
- Kỳ vọng: **85 dòng**, dòng đầu `8833 | 2026-09-01 | 30`

### ex06 · So với mặt bằng danh mục
Sản phẩm **đang bán** thuộc danh mục `'Trà'` và `'Cà phê'`. Mỗi sản phẩm kèm: giá trung bình của danh mục (làm tròn số nguyên), chênh lệch so với trung bình (làm tròn số nguyên), và % so với sản phẩm đắt nhất danh mục (1 chữ số).
- Cột: `category, id, price, avg_price, diff_from_avg, pct_of_max` · Sắp xếp: `category`, `price` giảm dần, `id`
- Kỳ vọng: **16 dòng**, dòng đầu `Cà phê | 13 | 397000.00 | 219143 | 177857 | 100.0`

---

## 🔴 Thực tế

### ex07 · Tăng trưởng MoM và YoY
Doanh thu tháng (giờ VN, đơn không `cancelled`/`refunded`). Với mỗi tháng 01–09/2026: % tăng so với **tháng trước** (`mom_pct`) và so với **cùng tháng năm 2025** (`yoy_pct`), làm tròn 1 chữ số. Dùng window function.
- Cột: `thang` (`YYYY-MM`), `revenue, mom_pct, yoy_pct` · Sắp xếp: `thang`
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01 | 2203041000.00 | -44.4 | 120.2`

### ex08 · Dấu hiệu khách sắp rời bỏ
Chỉ xét đơn `delivered`. Với mỗi khách: khoảng cách (ngày) giữa các đơn liên tiếp. `avg_gap_days` = trung bình các khoảng cách; `last_gap_days` = khoảng cách giữa **hai đơn gần nhất**. Tìm khách có **ít nhất 3 đơn** và `last_gap_days` **lớn hơn 3 lần** `avg_gap_days`. Làm tròn 1 chữ số khi hiển thị.
- Cột: `user_id, n_orders, avg_gap_days, last_gap_days` · Sắp xếp: tỉ lệ `last_gap / avg_gap` giảm dần, trùng thì `user_id`
- Kỳ vọng: **12 dòng**, dòng đầu `181 | 10 | 49.1 | 201.9`

### ex09 · Phát hiện bán âm kho
DB `lab`, bảng `i04.stock_moves(id, product_id, moved_at, qty)`: `qty` dương là nhập, âm là xuất. Tồn kho = cộng dồn `qty` theo thời gian (cùng thời điểm thì theo `id`). Với mỗi sản phẩm từng bị âm kho, tìm **lần đầu tiên** tồn kho xuống dưới 0.
- Cột: `product_id, move_id, moved_at_vn` (giờ VN, `timestamp`), `qty, balance` · Sắp xếp: `product_id`
- Kỳ vọng: **3 dòng**, dòng đầu `1 | 4 | 2026-10-02 15:00:00 | -3 | -2`

---

## 📏 ex10 · Câu hỏi quy mô: running total trên 10 triệu đơn
```sql
SELECT max(cum) FROM (SELECT sum(total_amount) OVER (ORDER BY created_at, id) AS cum FROM orders) t;
```
1. **Dự đoán** (ghi vào `answers/ex10.md`): thời gian ở `s`, `m`, `l`? Có tràn đĩa không? Thêm `ROWS UNBOUNDED PRECEDING` có nhanh hơn không? Thêm index `(created_at, id) INCLUDE (total_amount)` thì sao?
2. Đo bằng `bench/bench.sh <file> --scales s,m,l --runs 1`. Bản có index thì thử trong `BEGIN; CREATE INDEX …; EXPLAIN (ANALYZE, BUFFERS) …; ROLLBACK;`.
3. Vì sao không cách nào xuống dưới vài giây ở `l`? Cách sửa thật là gì?

Lời giải và số đo thật: `solutions/ex10.md`.
