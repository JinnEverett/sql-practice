# I08 · Bài tập (LATERAL, GROUPING SETS, pivot)

Bài 1–8 chạy trên **`shop_s`**. Trước khi làm bài 7, chạy `setup.sql` một lần (cài extension `tablefunc`; script chấm của ex07 tự chạy lại nó).
Mỗi bài một câu lệnh vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/I08-lateral-grouping 01`.
Múi giờ nghiệp vụ là giờ VN (`Asia/Ho_Chi_Minh`, +07); server chạy UTC (I05). `grouping()` là hàm bạn cần ở nhiều bài.

**Pass:** 6/8 (8 bài chấm tự động) + ex09 câu hỏi quy mô tự đối chiếu.

---

## 🟢 Cơ bản

### ex01 · Hai đơn mới nhất của mỗi khách
Với khách `id ≤ 5`, lấy **2 đơn mới nhất** (mọi trạng thái; trùng thời gian thì `id` lớn hơn trước). Viết bằng `LATERAL`.
- Cột: `user_id, order_id, created_at, total_amount` · Sắp xếp: `user_id`, `created_at` giảm dần
- Kỳ vọng: **10 dòng**, dòng đầu `1 | 9944 | 2026-09-29 07:11:21.945865+00 | 421000.00`

### ex02 · Đơn quý 3 theo quốc gia và trạng thái
Các đơn đặt từ 01/07 đến hết 30/09/2026 (giờ VN) của khách ở `JP` hoặc `SG`: số đơn theo (quốc gia, trạng thái), kèm dòng **tổng theo quốc gia** (nhãn trạng thái `'(tổng)'`) và **tổng chung** (nhãn quốc gia `'(tất cả)'`, trạng thái `'(tổng)'`). Dòng chi tiết trước, rồi tổng theo quốc gia, tổng chung cuối.
- Cột: `country, status, n_orders` · Sắp xếp: dòng chi tiết trước; trong cùng cấp theo `country`, `status`
- Kỳ vọng: **12 dòng**, dòng đầu `JP | cancelled | 6`, dòng cuối `(tất cả) | (tổng) | …`

### ex03 · Pivot trạng thái đơn theo tháng
Quý 3/2026 (giờ VN), mỗi tháng một dòng: tổng đơn, số đơn `delivered`, `cancelled`, `refunded`, và `khac` (mọi trạng thái còn lại). Tổng 4 cột con phải bằng tổng đơn. Không dùng extension.
- Cột: `thang` (text `'YYYY-MM'`), `n_orders, delivered, cancelled, refunded, khac` · Sắp xếp: `thang`
- Kỳ vọng: **3 dòng**, dòng đầu `2026-07 | 773 | 668 | 64 | 38 | 3`

---

## 🟡 Kết hợp

### ex04 · Device × loại event (có CUBE)
Chỉ xét event `add_to_cart` và `checkout`. Đếm theo (`device`, `event_type`) với **đủ mọi tổ hợp**: chi tiết, tổng theo device, tổng theo loại event, tổng chung. `device` lấy từ `properties->>'device'`. Một số event **thiếu key `device`**: ghi `'(không rõ)'`, và **không** được lẫn với nhãn `'(tất cả)'` của dòng tổng. Cột `lvl` là `grouping(device, event_type)`.
- Cột: `device, event_type, lvl, n_events` · Sắp xếp: `lvl`, `device`, `event_type`
- Kỳ vọng: **15 dòng**, dòng đầu `desktop | add_to_cart | 0 | 1830`

### ex05 · Doanh thu thanh toán: theo năm, theo phương thức, tổng
Bảng `payments`, chỉ `status = 'succeeded'`. Ba kiểu gom, **một lần quét**: theo **năm** (giờ VN), theo **phương thức** (`method`), và tổng chung. **Không** cần tổ hợp (năm, phương thức). Nhãn ô bị gộp: `'(mọi năm)'`, `'(mọi phương thức)'`. Cột `nam` là text.
- Cột: `nam, method, n_payments, amount` (`sum(amount)`) · Sắp xếp: dòng theo năm (năm tăng dần), rồi dòng theo phương thức, rồi tổng chung
- Kỳ vọng: **8 dòng**, dòng đầu `2024 | (mọi phương thức) | 664 | 4838251000.00`

### ex06 · Sản phẩm đắt nhất mỗi danh mục
Với **mỗi** danh mục (kể cả danh mục không có sản phẩm trực tiếp), tìm sản phẩm **đang bán** (`is_active`) giá cao nhất của danh mục đó (hòa giá thì `id` nhỏ hơn). Danh mục không có sản phẩm vẫn giữ dòng, cột sản phẩm là NULL.
- Cột: `category_id, category, product_id, product_name, price` · Sắp xếp: `category_id`
- Kỳ vọng: **42 dòng**, dòng đầu `1 | Thời trang | (NULL) | (NULL) | (NULL)`

### ex07 · Pivot doanh thu theo ngành × quý bằng crosstab
Doanh thu (`sum(quantity * unit_price)` của `order_items`) các đơn `delivered` đặt từ 01/01 đến hết 30/09/2026 (giờ VN), theo **ngành gốc** (danh mục cấp cao nhất, đi ngược `parent_id`; sản phẩm có thể nằm ở danh mục cấp 2 hoặc 3) và **quý**. Mỗi ngành một dòng, 3 cột `q1, q2, q3`. Dùng `crosstab` dạng 2 tham số.
- Cột: `root_name, q1, q2, q3` (numeric) · Sắp xếp: `root_name`
- Kỳ vọng: **8 dòng**, dòng đầu `Điện tử | 4937349000.00 | 6189088000.00 | 9943177000.00`

---

## 🔴 Thực tế

### ex08 · Báo cáo "ngành → danh mục" kèm tỉ trọng
Team BI báo: *"Cho em doanh thu tháng 9/2026 (giờ VN, chỉ đơn `delivered`) theo ngành và danh mục, có dòng tổng cho từng ngành và một dòng tổng toàn bộ, kèm % mỗi dòng chiếm trong dòng cha"*. Dòng danh mục so với tổng ngành của nó, dòng tổng ngành so với tổng chung, dòng tổng chung là 100. "Danh mục" là danh mục **trực tiếp** của sản phẩm; "ngành" là ngành gốc (như ex07). Một dòng `revenue` NULL hay thiếu nhãn là lỗi: dòng tổng ngành có `category_name = '(tổng ngành)'`, `cap = 'ngành'`; dòng tổng chung có `root_name = '(tất cả)'`, `category_name = '(tổng)'`, `cap = 'tổng'`; dòng chi tiết `cap = 'danh mục'`.
- Cột: `root_name, category_name, cap, revenue, pct_of_parent` (1 chữ số lẻ) · Sắp xếp: tổng chung cuối cùng; trong mỗi ngành, dòng tổng ngành trước, rồi các danh mục `revenue` giảm dần (hòa thì `category_name`); các ngành theo `root_name`
- Kỳ vọng: **43 dòng**, dòng đầu `Điện tử | (tổng ngành) | ngành | 3477921000.00 | 66.3`

---

## 📏 ex09 · Câu hỏi quy mô: top-2 đơn mỗi khách ở 1M đơn
Hai cách viết ex01 cho **toàn bộ** khách (không lọc `id ≤ 5`):
```sql
-- (A) LATERAL
SELECT u.id, o.id FROM users u CROSS JOIN LATERAL
  (SELECT id FROM orders WHERE user_id = u.id ORDER BY created_at DESC, id DESC LIMIT 2) o;
-- (B) row_number
SELECT user_id, id FROM (SELECT user_id, id, row_number() OVER
  (PARTITION BY user_id ORDER BY created_at DESC, id DESC) rn FROM orders) t WHERE rn <= 2;
```
1. **Dự đoán** (ghi vào `answers/ex09.md`): ở `s` (10k đơn), `m` (1M đơn): cách nào nhanh hơn, và nhanh hơn bao nhiêu lần? Index `(user_id, created_at DESC, id DESC)` giúp cách nào? Nếu chỉ cần top-2 cho **100 khách** thay vì toàn bộ thì sao?
2. Đo bằng `bench/bench.sh` và `EXPLAIN (ANALYZE, BUFFERS)` (tạo index trong `BEGIN … ROLLBACK`).
3. Giải thích: node nào xuất hiện, `loops=` bao nhiêu, vì sao.

Lời giải và số đo thật: `solutions/ex09.md`.
