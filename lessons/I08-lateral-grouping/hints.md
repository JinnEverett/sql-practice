# I08 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Hai đơn mới nhất
<details><summary>H1</summary>Subquery chạy lại cho từng khách, tham chiếu được cột của <code>users</code>: từ khóa <code>LATERAL</code>.</details>
<details><summary>H2</summary><code>FROM users u CROSS JOIN LATERAL (SELECT … FROM orders WHERE user_id = u.id ORDER BY … LIMIT 2) o</code>.</details>
<details><summary>H3</summary>Bên trong: <code>ORDER BY created_at DESC, id DESC LIMIT 2</code>. Bên ngoài: <code>WHERE u.id &lt;= 5 ORDER BY u.id, o.created_at DESC</code>.</details>

## ex02 · ROLLUP theo quốc gia và trạng thái
<details><summary>H1</summary>Cần dòng chi tiết + tổng từng quốc gia + tổng chung trong một câu: <code>ROLLUP</code>.</details>
<details><summary>H2</summary><code>GROUP BY ROLLUP (country, status)</code>; nhãn bằng <code>CASE WHEN grouping(col) = 1 …</code>. Lọc thời gian bằng nửa mở <code>&gt;= … AND &lt; …</code> kèm <code>+07</code>.</details>
<details><summary>H3</summary><code>ORDER BY grouping(country), country, grouping(status), status</code> để dòng tổng nằm đúng chỗ.</details>

## ex03 · Pivot theo tháng
<details><summary>H1</summary>Mỗi cột trạng thái là một <code>count(*)</code> có điều kiện: <code>FILTER</code>.</details>
<details><summary>H2</summary><code>count(*) FILTER (WHERE status = 'delivered')</code>. Tháng giờ VN: <code>created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'</code> rồi <code>date_trunc('month', …)</code>.</details>
<details><summary>H3</summary>Cột <code>khac</code>: <code>FILTER (WHERE status NOT IN ('delivered','cancelled','refunded'))</code>. <code>to_char(…, 'YYYY-MM')</code> cho nhãn tháng.</details>

## ex04 · CUBE với device thiếu
<details><summary>H1</summary>"Mọi tổ hợp" là <code>CUBE</code>. NULL ở dòng tổng và NULL do thiếu key là hai chuyện khác nhau.</details>
<details><summary>H2</summary><code>GROUP BY CUBE (properties-&gt;&gt;'device', event_type)</code>; hàm <code>grouping()</code> nhận đúng biểu thức đó để nhận ra dòng tổng.</details>
<details><summary>H3</summary>Nhãn device: <code>CASE WHEN grouping(properties-&gt;&gt;'device') = 1 THEN '(tất cả)' ELSE coalesce(properties-&gt;&gt;'device', '(không rõ)') END</code>. <code>lvl</code> = <code>grouping(properties-&gt;&gt;'device', event_type)</code>.</details>

## ex05 · GROUPING SETS
<details><summary>H1</summary>Chỉ ba kiểu gom, không có tổ hợp: <code>GROUPING SETS</code> (không phải ROLLUP/CUBE).</details>
<details><summary>H2</summary><code>GROUP BY GROUPING SETS ((năm), (method), ())</code>. Năm giờ VN: <code>extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code>; biểu thức phải viết giống hệt trong <code>SELECT</code>, <code>grouping()</code> và <code>ORDER BY</code>.</details>
<details><summary>H3</summary><code>ORDER BY grouping(năm), nam, grouping(method), method</code>. Nhãn bằng <code>CASE WHEN grouping(…) = 1</code>.</details>

## ex06 · Sản phẩm đắt nhất mỗi danh mục
<details><summary>H1</summary>Top-1 cho từng danh mục, và danh mục rỗng vẫn phải còn: LATERAL kiểu "outer".</details>
<details><summary>H2</summary><code>FROM categories c LEFT JOIN LATERAL (… LIMIT 1) p ON true</code>.</details>
<details><summary>H3</summary>Trong subquery: <code>WHERE category_id = c.id AND is_active ORDER BY price DESC, id LIMIT 1</code>.</details>

## ex07 · crosstab
<details><summary>H1</summary>Cần extension <code>tablefunc</code>. Truy vấn nguồn trả 3 cột: hàng, cột, giá trị. Ngành gốc: CTE đệ quy từ <code>parent_id IS NULL</code> (I02).</details>
<details><summary>H2</summary><code>crosstab($$ nguồn ORDER BY 1, 2 $$, $$ VALUES (1), (2), (3) $$) AS ct(root_name text, q1 numeric, q2 numeric, q3 numeric)</code>.</details>
<details><summary>H3</summary>Cột quý trong nguồn: <code>extract(quarter FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int</code>. Cách không cần crosstab: <code>sum(…) FILTER (WHERE quý = 1)</code> cho kết quả giống hệt.</details>

## ex08 · Báo cáo ngành → danh mục
<details><summary>H1</summary>Ba cấp (danh mục, ngành, tổng): <code>ROLLUP (root_name, category)</code>. Tỉ trọng so với dòng cha: lấy tổng cha bằng window function chạy <strong>trên kết quả đã gom</strong> (CTE).</details>
<details><summary>H2</summary>Trong CTE: <code>grouping(root_name, category) AS g</code> (0 = danh mục, 1 = tổng ngành, 3 = tổng chung). Ngoài: <code>revenue / max(revenue) FILTER (WHERE g = 1) OVER (PARTITION BY root_name)</code> cho dòng g = 0, và <code>FILTER (WHERE g = 3) OVER ()</code> cho g = 1.</details>
<details><summary>H3</summary>Mẫu: <code>round(100.0 * revenue / CASE g WHEN 0 THEN … WHEN 1 THEN … ELSE revenue END, 1)</code>. Sắp xếp: <code>ORDER BY g = 3, root_name, g DESC, revenue DESC, category_name</code>.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Đếm số lần subquery của LATERAL chạy (<code>loops=</code>) so với số dòng mà <code>row_number</code> phải đọc và sắp.</details>
<details><summary>H2</summary>Lọc bên trái xuống 100 khách thì LATERAL chỉ chạy 100 lần; <code>row_number</code> thì phải quét cả bảng trừ khi lọc <code>user_id</code> trong subquery.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex09.md</code> sau khi đã tự đo.</details>
