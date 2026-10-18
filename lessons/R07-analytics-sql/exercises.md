# R07 · Bài tập (Analytics SQL)

Bài 1–3, 6–8 chạy trên **`shop_s`**; bài 4–5 trên DB **`lab`** schema `r07` (script chấm tự chạy `setup.sql`); bài 9 là câu hỏi quy mô (tự đối chiếu).
Quy ước chung cho `shop_*`: **tháng/ngày theo giờ Việt Nam** (`AT TIME ZONE 'Asia/Ho_Chi_Minh'`); "mua hàng" = đơn có `status <> 'cancelled'` (trừ khi đề nói khác).
Tự chấm: `bash tools/check.sh lessons/R07-analytics-sql 01`.

**Pass:** 6/8 (8 bài chấm tự động + ex09 tự đối chiếu số đo).

---

## 🟢 Cơ bản

### ex01 · Kích thước cohort
Cohort của khách = tháng (giờ VN) của đơn mua đầu tiên. Đếm số khách trong mỗi cohort.
- Cột: `cohort_month` (ngày đầu tháng), `cohort_size` · Sắp xếp: `cohort_month`
- Kỳ vọng: **31 dòng**, dòng đầu `2024-03-01 | 4`

### ex02 · Retention 3 cohort đầu năm 2026
Cho các cohort 2026-01, 2026-02, 2026-03, với tháng thứ k = 0, 1, 2, 3 sau tháng đầu: số khách của cohort có mua ở tháng đó và tỉ lệ % so với kích thước cohort (1 chữ số lẻ). Ô nào không ai hoạt động vẫn phải hiện.
- Cột: `cohort_month, month_offset, active_users, retention_pct` · Sắp xếp: `cohort_month, month_offset`
- Kỳ vọng: **12 dòng**, dòng đầu `2026-01-01 | 0 | 41 | 100.0`

---

## 🟡 Kết hợp

### ex03 · Funnel tháng 9/2026
Visitor = `coalesce(user_id::text, anonymous_id)`. Funnel theo thứ tự trong tháng 9/2026 (giờ VN): (1) xem sản phẩm (`product_view`); (2) sau đó thêm vào giỏ (`add_to_cart`) **sau lần xem đầu tiên**; (3) sau đó thanh toán (`checkout`) **sau lần thêm giỏ đó**. Tính số visitor đến mỗi bước và % so với bước 1 (1 chữ số lẻ).
- Cột: `step, visitors, pct_of_step1` · Sắp xếp: thứ tự bước (1, 2, 3)
- Kỳ vọng: **3 dòng**, dòng đầu `product_view | 397 | 100.0`

### ex04 · Chuỗi ngày đăng nhập liên tiếp
`r07.logins(user_id, login_at)` (timestamptz, có người đăng nhập hai lần một ngày). Liệt kê mọi chuỗi ngày liên tiếp (theo ngày giờ VN) của mỗi user: ngày đầu, ngày cuối, số ngày.
- Cột: `user_id, streak_start, streak_end, days` · Sắp xếp: `user_id, streak_start`
- Kỳ vọng: **8 dòng**, dòng đầu `1 | 2026-03-01 | 2026-03-02 | 2`

### ex05 · Cắt phiên theo khoảng lặng
`r07.hits(visitor, at)`. Một phiên kết thúc khi im lặng **quá 30 phút** (đúng 30 phút vẫn cùng phiên). Với mỗi phiên: số thứ tự phiên trong visitor, thời điểm đầu, cuối, số sự kiện, thời lượng.
- Cột: `visitor, session_no` (số nguyên), `started_at, ended_at, n_events, duration` · Sắp xếp: `visitor, session_no`
- Kỳ vọng: **5 dòng**, dòng đầu `a | 1 | 2026-03-01 09:00:00+00 | 2026-03-01 09:40:00+00 | 3 | 00:40:00`

---

## 🔴 Thực tế

### ex06 · "Giá trị đơn trung bình tăng nhưng khách nói không thấy đắt hơn"
Team marketing báo giá trị đơn trung bình từng tháng 2026 tăng mạnh. Làm báo cáo trung thực hơn: với mỗi tháng từ 2026-01 đến 2026-09 (giờ VN), số đơn, trung bình, và các percentile p50, p90, p99 của `total_amount`, chỉ tính đơn thành công (`status NOT IN ('cancelled','refunded')`). Làm tròn tất cả thành số nguyên đồng.
- Cột: `month, n_orders, avg_amount, p50, p90, p99` · Sắp xếp: `month`
- Kỳ vọng: **9 dòng**, dòng đầu `2026-01-01 | 355 | 6205749 | 2039000 | 15769800 | 54158060`

### ex07 · DAU và WAU cuốn chiếu tháng 9
Với mỗi ngày trong tháng 9/2026 (giờ VN): DAU = số khách khác nhau có mua trong ngày; WAU = số khách khác nhau có mua trong 7 ngày kết thúc ở ngày đó (gồm cả ngày đó). Hoạt động = có đơn không bị `cancelled`. Có ngày nào không có đơn thì vẫn phải hiện dòng.
- Cột: `day, dau, wau` · Sắp xếp: `day`
- Kỳ vọng: **30 dòng**, dòng đầu `2026-09-01 | 26 | 157`

### ex08 · "Khách có quay lại mua không?"
Cho tất cả khách đã mua ít nhất một lần: số khách (`n_buyers`), số khách có đơn thứ hai (`n_repeat`), tỉ lệ mua lại % (`repeat_rate_pct`, 1 chữ số lẻ), và trung vị số ngày (ngày lịch giờ VN) từ đơn đầu đến đơn thứ hai trong số khách mua lại (`median_days_to_second`, 1 chữ số lẻ). Đơn xếp theo thời gian, trùng thì `id`.
- Cột: `n_buyers, n_repeat, repeat_rate_pct, median_days_to_second`
- Kỳ vọng: **1 dòng**: `986 | 939 | 95.2 | 28.0`

---

## 📏 ex09 · Câu hỏi quy mô: sessionization toàn bộ events
Áp dụng ex05 cho **toàn bộ** bảng `events` (visitor = `coalesce(user_id::text, anonymous_id)`, ngưỡng 30 phút), cuối cùng đếm số phiên.
1. **Dự đoán** (ghi vào `answers/ex09.md`): thời gian ở `s` (32k), `m` (3.2M), `l` (32M) với `work_mem` mặc định 4MB. Tăng `work_mem` lên 256MB có nhanh hơn không? Bước nào của plan tốn nhất: Sort hay WindowAgg?
2. Đo ở `shop_s` và `shop_m` bằng `EXPLAIN (ANALYZE, BUFFERS)`; thử `SET work_mem`, thử `COLLATE "C"` cho khóa phân vùng, thử một index biểu thức.
3. Giải thích kết quả và đề xuất cách để dashboard không phải chạy query này trên dữ liệu thô.

Lời giải và số đo thật: `solutions/ex09.md`.
