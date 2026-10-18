# R07 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Cohort
<details><summary>H1</summary>Bước 1: đơn đầu tiên của mỗi khách. Bước 2: đếm khách theo tháng của đơn đó.</details>
<details><summary>H2</summary>Subquery <code>SELECT user_id, min(created_at) … WHERE status &lt;&gt; 'cancelled' GROUP BY user_id</code>, rồi <code>date_trunc('month', first_order AT TIME ZONE 'Asia/Ho_Chi_Minh')</code>.</details>
<details><summary>H3</summary>Cast <code>::date</code> để cột ra ngày đầu tháng. Múi giờ áp dụng trước khi cắt tháng.</details>

## ex02 · Retention
<details><summary>H1</summary>Cần ba thứ: tháng của mỗi khách (khử trùng), cohort của khách, và một lưới cohort × (0..3).</details>
<details><summary>H2</summary><code>CROSS JOIN generate_series(0, 3)</code> cho lưới, <code>LEFT JOIN</code> hoạt động vào đúng tháng <code>cohort + k</code> (<code>make_interval(months =&gt; k)</code>), <code>count(o.user_id)</code> bỏ qua NULL.</details>
<details><summary>H3</summary>Mẫu số: <code>size</code> của cohort (đếm một lần ở CTE cohort). <code>round(100.0 * … / size, 1)</code>.</details>

## ex03 · Funnel
<details><summary>H1</summary>Mỗi bước cần mốc thời gian của bước trước để so "sau đó".</details>
<details><summary>H2</summary>CTE <code>s1</code> (t1 = min product_view), <code>s2</code> (t2 = min add_to_cart có created_at &gt; t1), <code>s3</code> (t3 = min checkout &gt; t2) bằng subquery tương quan.</details>
<details><summary>H3</summary>Số visitor đến bước k = <code>count(t_k)</code> (bỏ NULL). Ghép 3 con số thành 3 dòng bằng <code>LATERAL (VALUES …)</code> hoặc <code>UNION ALL</code>.</details>

## ex04 · Chuỗi ngày liên tiếp
<details><summary>H1</summary>Trong một chuỗi ngày liên tiếp, ngày trừ đi số thứ tự dòng cho cùng một giá trị.</details>
<details><summary>H2</summary>Khử trùng (user, ngày) trước: <code>SELECT DISTINCT user_id, (login_at AT TIME ZONE …)::date</code>. Rồi <code>day - (row_number() OVER (PARTITION BY user_id ORDER BY day))::int</code>.</details>
<details><summary>H3</summary><code>GROUP BY user_id, island</code> lấy <code>min(day)</code>, <code>max(day)</code>, <code>count(*)</code>.</details>

## ex05 · Sessionization
<details><summary>H1</summary>Hai bước cửa sổ: đánh dấu "đây là sự kiện mở phiên mới", rồi cộng dồn các cờ.</details>
<details><summary>H2</summary>Cờ = 1 nếu <code>at - lag(at) OVER (PARTITION BY visitor ORDER BY at) &gt; interval '30 minutes'</code> hoặc không có sự kiện trước (lag NULL). Số phiên = <code>sum(cờ) OVER (PARTITION BY visitor ORDER BY at)</code>.</details>
<details><summary>H3</summary>Gom bằng <code>GROUP BY visitor, session_no</code>; <code>session_no::int</code> vì <code>sum</code> trả bigint.</details>

## ex06 · Percentile
<details><summary>H1</summary>Trung bình bị đơn rất lớn kéo lên. Cần aggregate có thứ tự.</details>
<details><summary>H2</summary><code>percentile_cont(0.5) WITHIN GROUP (ORDER BY total_amount)</code> (trả double precision).</details>
<details><summary>H3</summary>Ép <code>::numeric</code> trước khi <code>round(…)</code> (round một tham số cần numeric). Lọc đơn và khoảng 2026-01..09 theo giờ VN.</details>

## ex07 · DAU/WAU
<details><summary>H1</summary>Khách khác nhau trong 7 ngày không bằng tổng DAU của 7 ngày.</details>
<details><summary>H2</summary>Lưới ngày bằng <code>generate_series</code>; <code>LEFT JOIN</code> bảng (ngày, khách) với <code>o.day BETWEEN days.day - 6 AND days.day</code>; <code>count(DISTINCT user_id)</code>.</details>
<details><summary>H3</summary>DAU: <code>count(DISTINCT user_id) FILTER (WHERE o.day = days.day)</code>. Lấy dữ liệu từ 6 ngày trước ngày đầu tiên của tháng.</details>

## ex08 · Mua lại
<details><summary>H1</summary>Cần ngày của đơn thứ nhất và đơn thứ hai của mỗi khách.</details>
<details><summary>H2</summary><code>row_number() OVER (PARTITION BY user_id ORDER BY created_at, id)</code>, rồi <code>max(day) FILTER (WHERE rn = 1)</code> và <code>… rn = 2</code> theo khách.</details>
<details><summary>H3</summary>Mẫu số tỉ lệ: <code>count(*)</code> (mọi khách). Trung vị: <code>percentile_cont(0.5) WITHIN GROUP (ORDER BY second_day - first_day)</code> (NULL tự bị bỏ qua).</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Đọc plan: thời gian của node Sort so với WindowAgg.</details>
<details><summary>H2</summary>Sort theo khóa text cần so sánh chuỗi theo collation của database.</details>
<details><summary>H3</summary>Khóa dùng để gom nhóm (partition) không cần thứ tự ngôn ngữ: <code>COLLATE "C"</code>.</details>
