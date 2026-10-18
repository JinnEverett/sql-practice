# I01 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Khách chi tiêu vượt trội
<details><summary>H1</summary>Tạo một CTE "tổng chi tiêu mỗi khách", rồi dùng nó <b>hai lần</b>: để lọc và để tính trung bình.</details>
<details><summary>H2</summary><code>WITH user_totals AS (SELECT user_id, sum(total_amount) AS total_spent … GROUP BY user_id) SELECT … FROM user_totals WHERE total_spent &gt; 3 * (SELECT avg(…) FROM user_totals)</code></details>
<details><summary>H3</summary>Trung bình là <code>avg(total_spent)</code> lấy từ CTE, không phải <code>avg(total_amount)</code> lấy từ <code>orders</code>.</details>

## ex02 · Tháng kỷ lục mỗi năm
<details><summary>H1</summary>Hai bước: doanh thu từng tháng, rồi max mỗi năm. Sau đó JOIN để biết tháng nào đạt max.</details>
<details><summary>H2</summary>CTE <code>monthly(m, revenue)</code> với <code>m = date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code>; CTE <code>best(y, revenue)</code> từ monthly.</details>
<details><summary>H3</summary><code>JOIN best ON best.y = extract(year FROM monthly.m) AND best.revenue = monthly.revenue</code>; ép <code>extract(...)::int</code> cho cột nam/thang.</details>

## ex03 · Tỉ trọng phương thức
<details><summary>H1</summary>Một CTE giữ đúng tập giao dịch cần xét, một CTE (hoặc subquery) tính tổng.</details>
<details><summary>H2</summary>Lọc <code>status = 'succeeded'</code> và khoảng thời gian +07 ngay trong CTE đầu, để mẫu số cũng chỉ gồm giao dịch thành công.</details>
<details><summary>H3</summary><code>round(100.0 * sum(amount) / (SELECT s FROM total), 1)</code>.</details>

## ex04 · Tăng trưởng so với tháng trước
<details><summary>H1</summary>Self join CTE monthly với chính nó, lệch nhau 1 tháng.</details>
<details><summary>H2</summary><code>FROM monthly cur LEFT JOIN monthly prev ON prev.m = cur.m - interval '1 month'</code>. CTE phải gồm cả tháng 12/2025.</details>
<details><summary>H3</summary>Lọc CTE từ <code>'2025-12-01 00:00+07'</code>, rồi ở câu chính lọc <code>WHERE cur.m &gt;= '2026-01-01'</code>; <code>to_char(cur.m, 'YYYY-MM')</code>.</details>

## ex05 · Xem nhiều mà ít thêm giỏ
<details><summary>H1</summary>Gom mỗi loại event theo sản phẩm trong một CTE riêng, rồi mới JOIN.</details>
<details><summary>H2</summary><code>(properties-&gt;&gt;'product_id')::bigint</code>; <code>views LEFT JOIN carts</code>; <code>coalesce(n_carts, 0)</code>.</details>
<details><summary>H3</summary><code>WHERE v.n_views &gt;= 50 ORDER BY cart_rate, v.product_id LIMIT 10</code>; JOIN thêm <code>products</code> để lấy tên.</details>

## ex06 · Lưu trữ đơn đã hủy
<details><summary>H1</summary><code>DELETE … RETURNING</code> đặt trong WITH, rồi INSERT từ CTE đó.</details>
<details><summary>H2</summary><code>WITH moved AS (DELETE FROM i01.orders WHERE … RETURNING …) INSERT INTO i01.orders_archive (…) SELECT … FROM moved;</code></details>
<details><summary>H3</summary>Điều kiện: <code>status = 'cancelled' AND created_at &lt; '2026-07-01 00:00+07'</code>; liệt kê rõ 5 cột khi INSERT để <code>archived_at</code> nhận default.</details>

## ex07 · Tạo đơn kèm dòng hàng
<details><summary>H1</summary>Ba khối: danh sách dòng hàng (VALUES), INSERT đơn có RETURNING id, INSERT dòng hàng dùng id đó.</details>
<details><summary>H2</summary><code>WITH items (line_no, product_id, quantity, unit_price) AS (VALUES …), o AS (INSERT INTO i01.orders (…) SELECT …, sum(quantity * unit_price) FROM items RETURNING id) INSERT INTO i01.order_items … SELECT … FROM o CROSS JOIN items</code></details>
<details><summary>H3</summary>Literal tiền ghi dạng <code>100000.00</code> hoặc ép <code>::numeric</code>; thời điểm <code>'2026-10-17 10:00+07'</code>.</details>

## ex08 · Khách mới và tỉ lệ quay lại
<details><summary>H1</summary>Bước 1: đơn đầu của mỗi khách (bỏ đơn cancelled). Bước 2: lọc khách có đơn đầu trong khoảng, gắn cờ "mua lại" bằng EXISTS. Bước 3: đếm theo tháng.</details>
<details><summary>H2</summary>Cờ: <code>EXISTS (SELECT 1 FROM orders o WHERE o.user_id = f.user_id AND o.status &lt;&gt; 'cancelled' AND o.created_at &gt; f.first_at AND o.created_at &lt;= f.first_at + interval '30 days')</code></details>
<details><summary>H3</summary><code>count(*) FILTER (WHERE repeated)</code>; tháng: <code>to_char(date_trunc('month', first_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM')</code>.</details>

## ex09 · Đối soát tổng tiền
<details><summary>H1</summary>Gom dòng hàng theo đơn trong CTE, rồi mới JOIN với orders.</details>
<details><summary>H2</summary><code>expected = items_total + shipping_fee - discount_amount</code>; lọc <code>total_amount &lt;&gt; expected</code>.</details>
<details><summary>H3</summary>ORDER BY không dùng được alias trong biểu thức: viết lại <code>abs(o.total_amount - (…))</code>.</details>
