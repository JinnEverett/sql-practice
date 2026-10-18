# R07 · Analytics SQL

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s` và DB `lab` (schema `r07`, dữ liệu nhỏ để tính tay được). Cần window function (I03, I04) và date/time (I05).

## Mục tiêu: sau buổi này bạn làm được
- Dựng **cohort** và bảng retention, kể cả ô có giá trị 0.
- Tính **funnel theo thứ tự** thời gian và hiểu vì sao đếm độc lập từng bước là sai.
- Giải **gaps & islands** (chuỗi ngày liên tiếp) và **sessionization** (cắt phiên theo khoảng lặng).
- Dùng **percentile** thay trung bình cho dữ liệu lệch; đếm khách khác nhau trong cửa sổ cuốn chiếu (DAU/WAU).
- Biết các query này tuyến tính theo N, và chỗ nào tốn nhất.

---

## 1. Quy ước chung cho số liệu
- **Định nghĩa trước, SQL sau:** "khách mua" là ai (đơn `cancelled` có tính không)? "Tháng" theo múi giờ nào? Hai người đọc cùng báo cáo phải ra cùng số. Ở `shop_*`: bỏ đơn `cancelled`, tháng theo giờ Việt Nam (`created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'`).
- **Định danh visitor:** `coalesce(user_id::text, anonymous_id)`. Một người có thể xuất hiện bằng cả hai id trước và sau khi đăng nhập (nếu không có bảng ánh xạ, số visitor bị đếm dư). Đây là giới hạn của dữ liệu, ghi chú trong báo cáo.
- **Khử trùng trước khi đếm:** `count(DISTINCT user_id)` hoặc `GROUP BY` ở bước đệm.

## 2. Cohort và retention
```sql
WITH o AS (SELECT user_id, date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS m
           FROM orders WHERE status <> 'cancelled' GROUP BY 1, 2),         -- (khách, tháng có mua)
     first AS (SELECT user_id, min(m) AS cohort FROM o GROUP BY user_id)    -- cohort của khách
SELECT cohort, count(*) AS cohort_size FROM first GROUP BY 1 ORDER BY 1;
```
Retention tháng k = số khách của cohort có mua ở tháng `cohort + k` / kích thước cohort. Dựng **lưới** cohort × k bằng `generate_series` + `CROSS JOIN` rồi `LEFT JOIN` hoạt động vào để ô không ai hoạt động hiện 0 (ex02). Mẫu số là kích thước cohort, không phải số người hoạt động.

## 3. Funnel
Funnel đúng là **theo thứ tự**: một visitor chỉ ở bước 2 nếu `add_to_cart` xảy ra *sau* `product_view` đầu tiên của họ. Mỗi bước dùng mốc thời gian của bước trước (ex03). Đếm `count(DISTINCT visitor)` cho từng loại event độc lập sẽ làm bước sau có thể đông hơn bước trước (ở dữ liệu mẫu: add_to_cart 337 visitor nếu đếm độc lập, nhưng chỉ 212 nếu theo thứ tự).
Định nghĩa còn mơ hồ: giới hạn trong một phiên hay bất kỳ lúc nào trong tháng? Chọn và ghi rõ.

## 4. Gaps & islands
Mẹo: trong mỗi chuỗi ngày liên tiếp, `ngày − row_number()` là hằng số.
```sql
SELECT user_id, min(day), max(day), count(*)
FROM (SELECT user_id, day, day - (row_number() OVER (PARTITION BY user_id ORDER BY day))::int AS island
      FROM (SELECT DISTINCT user_id, login_at::date AS day FROM logins) d) g
GROUP BY user_id, island;
```
**Khử trùng** (user, ngày) trước (hai lần đăng nhập một ngày làm lệch row_number) và chốt múi giờ trước khi cắt ngày (ex04). Biến thể: khoảng trống (gaps) = hai "đảo" liền kề; chuỗi theo giờ/phút thì dùng `epoch` chia bước.

## 5. Sessionization
Phiên mới bắt đầu khi khoảng lặng so với sự kiện trước > ngưỡng (ex05):
```sql
sum(CASE WHEN at - lag(at) OVER w > interval '30 minutes' OR lag(at) OVER w IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY visitor ORDER BY at)
```
`lag` cho khoảng lặng; tổng lũy kế của cờ "phiên mới" cho số thứ tự phiên. Ngưỡng "đúng 30 phút" vẫn cùng phiên (dùng `>` chứ không `>=`), nêu rõ trong định nghĩa.

## 6. Percentile, DAU/WAU
- Giá trị đơn hàng lệch phải: trung bình bị whale kéo lên (tháng 1/2026 ở `shop_s`: avg ≈ 6.2 triệu, median ≈ 2.0 triệu). Báo cáo dùng `percentile_cont(0.5) WITHIN GROUP (ORDER BY x)`. `_cont` nội suy, `_disc` chọn một giá trị có thật. Aggregate này cần sắp xếp cả nhóm: tốn hơn `avg`.
- Số khách **khác nhau** trong cửa sổ không cộng được từ từng ngày, và Postgres không có `count(DISTINCT …) OVER (…)`. Dựng lưới ngày rồi `JOIN` theo khoảng ngày và `count(DISTINCT …)` (ex07), hoặc dùng xấp xỉ (HyperLogLog extension) khi quy mô lớn.

## 7. Quy mô
Mọi query ở đây phải đọc toàn bộ phần dữ liệu liên quan: O(N). Điểm cần để ý là **Sort** (window/percentile cần dữ liệu có thứ tự): sắp xếp 3.2M dòng theo khóa text mất ~8 giây với collation `en_US.utf8`, và đổi khóa phân vùng sang `COLLATE "C"` giúp gần gấp rưỡi (ex09). Dashboard nên đọc bảng tổng hợp theo ngày/tháng (cập nhật tăng dần, I09 và D09), không quét lại event thô.

## Bẫy hay gặp
1. Cắt tháng/ngày theo UTC thay vì giờ nghiệp vụ.
2. INNER JOIN làm mất ô retention bằng 0.
3. Mẫu số sai (số người hoạt động thay vì cohort).
4. Funnel không theo thứ tự.
5. Quên khử trùng trước khi gaps & islands.
6. Trung bình thay median cho dữ liệu lệch; `percentile_disc` vs `_cont`.
7. Cộng DAU để ra WAU.

## Postgres-specific
- `FILTER (WHERE …)` cho aggregate có điều kiện (gọn hơn `CASE`); `WITHIN GROUP` cho ordered-set aggregate (`percentile_*`, `mode`); `WINDOW w AS (…)` đặt tên cửa sổ dùng lại.
- `date - integer` cho ra `date`; `date - date` cho ra số ngày (integer).
