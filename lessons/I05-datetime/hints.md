# I05 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Lịch mua
<details><summary>H1</summary>Bắt đầu từ <code>generate_series</code> của 30 ngày, LEFT JOIN orders.</details>
<details><summary>H2</summary>Điều kiện JOIN gồm <code>o.user_id = 1</code> và ngày VN của đơn = ngày lịch. Đặt điều kiện user trong ON, không phải WHERE.</details>
<details><summary>H3</summary><code>count(o.id)</code>, <code>GROUP BY d</code>, <code>d::date AS ngay</code>.</details>

## ex02 · Giờ vàng
<details><summary>H1</summary>Bảng giờ = <code>generate_series(0, 23)</code>.</details>
<details><summary>H2</summary>Gom <code>extract(hour FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code> trong CTE, rồi LEFT JOIN vào bảng giờ.</details>
<details><summary>H3</summary><code>round(100.0 * coalesce(n, 0) / sum(coalesce(n, 0)) OVER (), 1)</code>.</details>

## ex03 · Giờ địa phương
<details><summary>H1</summary>Bảng ánh xạ quốc gia → múi giờ bằng <code>VALUES</code>. <code>AT TIME ZONE</code> nhận tên múi giờ từ một cột.</details>
<details><summary>H2</summary><code>orders JOIN users JOIN tz ON tz.country = u.country</code>; đếm bằng <code>count(*) FILTER (WHERE extract(hour FROM o.created_at AT TIME ZONE tz.zone) &lt; 6)</code>.</details>
<details><summary>H3</summary>Cột thứ 4 giống cột thứ 3 nhưng dùng <code>'Asia/Ho_Chi_Minh'</code>. Đừng viết offset cố định cho Sydney/LA.</details>

## ex04 · Tuần ISO
<details><summary>H1</summary><code>date_trunc('week', …)</code> cho thứ Hai đầu tuần; nhãn bằng <code>to_char</code> với mẫu năm ISO.</details>
<details><summary>H2</summary>Mẫu <code>'IYYY-"W"IW'</code>. GROUP BY theo <code>date_trunc('week', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code>.</details>
<details><summary>H3</summary>Cột thu_hai: <code>date_trunc('week', …)::date</code>; ORDER BY thu_hai.</details>

## ex05 · Đơn treo
<details><summary>H1</summary>Ngưỡng = mốc − <code>interval '3 days'</code>.</details>
<details><summary>H2</summary><code>timestamptz '2026-10-01 00:00+07' - created_at</code> là interval. Cắt bằng <code>date_trunc('hour', interval)</code>.</details>
<details><summary>H3</summary><code>justify_hours(date_trunc('hour', timestamptz '2026-10-01 00:00+07' - created_at))</code>; <code>status IN ('pending', 'paid')</code>.</details>

## ex06 · Lưới khách × tháng
<details><summary>H1</summary>CROSS JOIN users (21..25) với 6 tháng từ generate_series, rồi LEFT JOIN số đơn.</details>
<details><summary>H2</summary>Số đơn gom sẵn theo <code>(user_id, date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'))</code>. Tháng sinh bằng <code>generate_series(timestamp '2026-01-01', timestamp '2026-06-01', interval '1 month')</code>.</details>
<details><summary>H3</summary>Điều kiện LEFT JOIN: <code>monthly.user_id = u.id AND monthly.m = months.m</code>; <code>coalesce(monthly.n, 0)</code>.</details>

## ex07 · SLA thanh toán
<details><summary>H1</summary>Mỗi đơn chỉ lấy lần thanh toán thành công đầu tiên. Đơn chưa thanh toán vẫn phải có mặt.</details>
<details><summary>H2</summary><code>DISTINCT ON (order_id) … ORDER BY order_id, created_at, id</code> trên payments succeeded; <code>orders LEFT JOIN first_pay</code>.</details>
<details><summary>H3</summary><code>coalesce(f.method, '(chưa thanh toán)')</code>; đạt SLA: <code>f.paid_at - o.created_at &lt;= interval '15 minutes'</code>.</details>

## ex08 · Bao lâu mới mua
<details><summary>H1</summary>Mỗi khách: <code>min(o.created_at) - u.created_at</code>, đổi ra ngày. LEFT JOIN để giữ khách chưa mua.</details>
<details><summary>H2</summary><code>extract(epoch FROM …) / 86400</code>; khách chưa mua có giá trị NULL, khách dữ liệu lỗi có giá trị âm.</details>
<details><summary>H3</summary><code>count(*) FILTER (WHERE days &gt;= 0)</code>, <code>count(*) FILTER (WHERE days IS NULL)</code>, <code>avg(days) FILTER (WHERE days &gt;= 0)</code>.</details>

## ex09 · Ngày xử lý
<details><summary>H1</summary>Với mỗi đơn, sinh vài ngày tới và chọn ngày nhỏ nhất thỏa điều kiện "là ngày làm việc".</details>
<details><summary>H2</summary>Scalar subquery: <code>(SELECT min(g::date) FROM generate_series(ngay_dat, ngay_dat + 10, interval '1 day') g WHERE …)</code>. Ngày lễ để trong CTE <code>VALUES</code>.</details>
<details><summary>H3</summary>Điều kiện: <code>extract(isodow FROM g) &lt; 6 AND g::date NOT IN (SELECT d FROM holidays)</code>. Lọc đơn: <code>id % 5 = 0</code>.</details>
