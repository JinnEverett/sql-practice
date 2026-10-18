# I04 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Lũy kế tháng 9
<details><summary>H1</summary>Gom theo ngày trước, rồi <code>sum(revenue) OVER (ORDER BY ngay)</code>.</details>
<details><summary>H2</summary>CTE <code>daily(ngay, revenue)</code> với <code>(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date</code>.</details>
<details><summary>H3</summary>Frame mặc định khi có ORDER BY đã là "từ đầu tới dòng hiện tại".</details>

## ex02 · Khoảng cách giữa các đơn
<details><summary>H1</summary><code>lag(created_at) OVER (…)</code>.</details>
<details><summary>H2</summary><code>created_at - lag(created_at) OVER (PARTITION BY user_id ORDER BY created_at, id)</code> là interval.</details>
<details><summary>H3</summary><code>round(extract(epoch FROM …) / 86400, 1)</code>.</details>

## ex03 · Trung bình trượt 7 ngày
<details><summary>H1</summary><code>ROWS BETWEEN 6 PRECEDING AND CURRENT ROW</code>. Ngày 01/09 cần 6 ngày trước đó.</details>
<details><summary>H2</summary>CTE daily lấy từ <code>'2026-08-26 00:00+07'</code>; tính <code>avg(…) OVER (…)</code> trong một CTE thứ hai; lọc tháng 9 ở câu chính.</details>
<details><summary>H3</summary><code>round(avg(revenue) OVER (ORDER BY ngay ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))</code>, ngoài: <code>WHERE ngay &gt;= date '2026-09-01'</code>.</details>

## ex04 · Đơn đầu, đơn cuối
<details><summary>H1</summary><code>first_value</code> / <code>last_value</code>. Frame mặc định kết thúc ở đâu?</details>
<details><summary>H2</summary>Mở frame: <code>ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING</code>.</details>
<details><summary>H3</summary><code>WINDOW w AS (ORDER BY created_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)</code>; <code>max(total_amount) OVER w</code>.</details>

## ex05 · Lũy kế theo ngày
<details><summary>H1</summary>Hai đơn cùng ngày phải cùng số: frame nào gộp các dòng đồng hạng?</details>
<details><summary>H2</summary><code>count(*) OVER (ORDER BY &lt;ngày VN&gt;)</code> với frame mặc định (RANGE). Đừng thêm id vào ORDER BY của OVER.</details>
<details><summary>H3</summary><code>count(*) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)</code>.</details>

## ex06 · So với danh mục
<details><summary>H1</summary>Window không có ORDER BY → frame = cả partition.</details>
<details><summary>H2</summary><code>avg(p.price) OVER (PARTITION BY p.category_id)</code>, <code>max(p.price) OVER (PARTITION BY p.category_id)</code>.</details>
<details><summary>H3</summary>JOIN categories để lọc tên và lấy cột <code>category</code>; <code>round(100.0 * p.price / max(…) OVER (…), 1)</code>.</details>

## ex07 · MoM và YoY
<details><summary>H1</summary><code>lag(revenue, 1)</code> và <code>lag(revenue, 12)</code> trên bảng tháng. Lấy dữ liệu từ 2025.</details>
<details><summary>H2</summary>CTE monthly từ <code>'2025-01-01 00:00+07'</code>; CTE thứ hai tính lag; câu chính lọc <code>m &gt;= '2026-01-01'</code>.</details>
<details><summary>H3</summary><code>round(100.0 * (revenue - prev_y) / prev_y, 1)</code>.</details>

## ex08 · Sắp rời bỏ
<details><summary>H1</summary>Bước 1: khoảng cách mỗi đơn tới đơn trước (lag). Bước 2: gom theo khách. Khoảng cách cuối = khoảng cách của đơn mới nhất.</details>
<details><summary>H2</summary>Đánh dấu đơn mới nhất bằng <code>row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC)</code>; <code>avg(gap)</code> tự bỏ NULL.</details>
<details><summary>H3</summary><code>max(gap_days) FILTER (WHERE rn_desc = 1) AS last_gap</code>; lọc <code>n_orders &gt;= 3 AND last_gap &gt; 3 * avg_gap</code>; sắp <code>last_gap / avg_gap DESC</code>.</details>

## ex09 · Bán âm kho
<details><summary>H1</summary>Số dư = cộng dồn từng dòng. Hai dòng cùng thời điểm: frame mặc định làm gì với chúng?</details>
<details><summary>H2</summary><code>sum(qty) OVER (PARTITION BY product_id ORDER BY moved_at, id ROWS UNBOUNDED PRECEDING)</code>.</details>
<details><summary>H3</summary>Lọc <code>balance &lt; 0</code> rồi lấy dòng đầu mỗi sản phẩm bằng <code>row_number()</code> (hoặc <code>DISTINCT ON (product_id)</code>).</details>
