# I03 · Bài tập (Window I: ranking)

Tất cả chạy trên **`shop_s`**. Mỗi bài một câu lệnh vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/I03-window-ranking 01`.
**Pass:** 8/9 bài chấm tự động. Bài 10 là câu hỏi quy mô (tự đối chiếu).

## 🟢 Cơ bản

### ex01 · Top 3 đắt nhất mỗi danh mục
Với mỗi danh mục, lấy 3 sản phẩm **đang bán** đắt nhất (trùng giá thì `id` nhỏ trước). `rn` = thứ hạng 1..3.
- Cột: `category_id, id, name, price, rn` · Sắp xếp: `category_id`, `rn`
- Kỳ vọng: **99 dòng**, dòng đầu `9 | 189 | Áo nam Biti's A255 | 590000.00 | 1`

### ex02 · rank, dense_rank, row_number
Khách ở `city = 'Huế'`, xếp theo **số đơn `delivered`** giảm dần. Cho cả 3 kiểu hạng: `rnk` (rank), `drnk` (dense_rank), `rn` (row_number, trùng thì `user_id` nhỏ trước). Chỉ lấy khách có `drnk ≤ 5`.
- Cột: `user_id, n_orders, rnk, drnk, rn` · Sắp xếp: `rn`
- Kỳ vọng: **6 dòng**, dòng đầu `25 | 33 | 1 | 1 | 1`

### ex03 · Chia 4 nhóm chi tiêu
Khách có đơn `delivered`, tổng chi tiêu = tổng `total_amount` các đơn đó. Chia thành 4 nhóm số người gần bằng nhau bằng `ntile`, nhóm 1 = chi nhiều nhất (trùng thì `user_id` nhỏ trước).
- Cột: `quartile, n_users, min_spent, max_spent` · Sắp xếp: `quartile`
- Kỳ vọng: **4 dòng**, dòng đầu `1 | 242 | 61817000.00 | 5884970000.00`

## 🟡 Kết hợp

### ex04 · Top 3 khách mỗi thành phố
Khách `country = 'VN'` có `city` (gộp 4 cách viết TP.HCM về `TP. Hồ Chí Minh` như F10 ex02; bỏ khách không có city). Top 3 theo tổng chi tiêu `delivered` trong mỗi thành phố (trùng thì `user_id` nhỏ trước).
- Cột: `city_norm, user_id, full_name, total_spent, rnk` · Sắp xếp: `city_norm`, `rnk`
- Kỳ vọng: **21 dòng**, dòng đầu `Cần Thơ | 11 | Lê Thanh Ngọc | 563450000.00 | 1`

### ex05 · Tài khoản trùng email
Email trùng khi `lower(trim(email))` giống nhau. Mỗi nhóm giữ bản **đăng ký sớm nhất** (`created_at`, hòa thì `id` nhỏ). Liệt kê các bản trùng kèm `id` bản được giữ.
- Cột: `dup_id, keep_id, email_norm` · Sắp xếp: `dup_id`
- Kỳ vọng: **5 dòng**, dòng đầu `7 | 4 | minh.tran4@yahoo.com`

### ex06 · Doanh thu đơn đầu tiên và đơn mua lại
Bỏ đơn `cancelled`. "Đơn đầu tiên" là đơn sớm nhất của khách **trong toàn bộ lịch sử**. Với mỗi tháng 01–09/2026 (giờ VN): tổng `total_amount` của các đơn là đơn đầu tiên, và của các đơn mua lại.
- Cột: `thang` (`YYYY-MM`), `first_order_revenue, repeat_revenue` · Sắp xếp: `thang`
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01 | 207019000.00 | 2209436000.00`

## 🔴 Thực tế

### ex07 · Sản phẩm bán chạy nhất mỗi tháng
Tháng 01–09/2026 (giờ VN), đơn không `cancelled`/`refunded`: sản phẩm có **tổng số lượng** bán cao nhất mỗi tháng. Đồng hạng nhất thì liệt kê **tất cả**.
- Cột: `thang, product_id, name, units` · Sắp xếp: `thang`, `product_id`
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01 | 1 | Ốp lưng Samsung C4CA | 129`

### ex08 · Top 1% khách đóng góp bao nhiêu?
Khách có đơn `delivered`, xếp theo tổng chi tiêu giảm dần (trùng thì `user_id` nhỏ trước), chia 100 phần bằng `ntile(100)`: phần 1 = `'top 1%'`, phần 2–10 = `'top 2-10%'`, còn lại `'còn lại'`. Mỗi nhóm: số khách, doanh thu, % doanh thu (làm tròn 1 chữ số).
- Cột: `nhom, n_users, revenue, pct_revenue` · Sắp xếp: top 1% → còn lại
- Kỳ vọng: **3 dòng**, dòng đầu `top 1% | 10 | 13736228000.00 | 23.8`

### ex09 · Thay đổi thứ hạng tháng 9 so với tháng 8
Doanh thu sản phẩm = `quantity × unit_price`, đơn không `cancelled`/`refunded`, tháng giờ VN. Xếp hạng (rank) sản phẩm theo doanh thu trong từng tháng 8 và 9/2026. Với **top 10 tháng 9**: hạng tháng 9, hạng tháng 8 (NULL nếu tháng 8 không bán), `change = rank_aug − rank_sep`.
- Cột: `product_id, name, rank_sep, rank_aug, change` · Sắp xếp: `rank_sep`, `product_id`
- Kỳ vọng: **10 dòng**, dòng đầu `121 | Điện thoại Samsung 4C56 | 1 | 10 | 9`

---

## 📏 ex10 · Câu hỏi quy mô: đơn mới nhất của mỗi khách ở 10 triệu đơn
```sql
-- A
SELECT count(*), sum(total_amount) FROM (
  SELECT user_id, total_amount, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn FROM orders) t
WHERE rn = 1;
-- B
SELECT count(*), sum(total_amount) FROM (
  SELECT DISTINCT ON (user_id) user_id, total_amount FROM orders ORDER BY user_id, created_at DESC, id DESC) t;
```
1. **Dự đoán trước** (ghi vào `answers/ex10.md`): ở `s`, `m`, `l` mỗi câu mất bao lâu? Có tràn đĩa không, bao nhiêu MB? Câu nào nhanh hơn?
2. Đo: lưu mỗi câu vào một file, chạy `bench/bench.sh <file> --scales s,m,l --runs 1`.
3. Thử thêm trên `shop_m` (trong transaction để khỏi để lại index):
   `BEGIN; CREATE INDEX ON orders (user_id, created_at DESC, id DESC) INCLUDE (total_amount); EXPLAIN (ANALYZE, BUFFERS) <câu A>; ROLLBACK;`
   Plan đổi thế nào? Vì sao vẫn phải đọc cả bảng?

Lời giải và số đo thật: `solutions/ex10.md`.
