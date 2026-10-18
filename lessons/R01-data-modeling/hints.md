# R01 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Đưa về 1NF
<details><summary>H1</summary>Cần một hàm "tách chuỗi thành nhiều dòng" rồi tách tiếp từng phần tử <code>sku:qty</code>.</details>
<details><summary>H2</summary><code>string_to_table(items, ',')</code> trong <code>FROM</code> (lateral ngầm), rồi <code>split_part(phần_tử, ':', n)</code>.</details>
<details><summary>H3</summary><code>FROM r01.legacy_orders o, string_to_table(o.items, ',') AS it</code>; <code>split_part(it, ':', 2)::int</code>.</details>

## ex02 · Vi phạm phụ thuộc hàm
<details><summary>H1</summary>Nếu <code>A → B</code> thì mỗi giá trị <code>A</code> chỉ có một giá trị <code>B</code>. Làm sao đếm "số giá trị khác nhau"?</details>
<details><summary>H2</summary><code>GROUP BY khóa HAVING count(DISTINCT thuộc_tính) &gt; 1</code>, lặp cho từng cặp rồi <code>UNION ALL</code>.</details>
<details><summary>H3</summary>Có 3 cặp cần kiểm: (customer_id, customer_name), (customer_id, customer_city), (sku, product_name). Đừng kiểm unit_price.</details>

## ex03 · Tách bảng
<details><summary>H1</summary>Tạo bảng cha trước (customers, products), rồi orders, cuối cùng order_lines. Mỗi bảng một khóa chính.</details>
<details><summary>H2</summary>Chọn đúng một dòng cho mỗi khóa theo thứ tự ưu tiên: <code>SELECT DISTINCT ON (customer_id) … ORDER BY customer_id, line_id DESC</code>.</details>
<details><summary>H3</summary><code>REFERENCES r01.customers</code> ngay trong định nghĩa cột; <code>PRIMARY KEY (order_id, sku)</code> ở cuối <code>order_lines</code>; <code>orders</code> lấy <code>SELECT DISTINCT order_id, ordered_on, customer_id</code>.</details>

## ex04 · UNIQUE có NULL
<details><summary>H1</summary>Mặc định mọi NULL là "khác nhau" trong UNIQUE.</details>
<details><summary>H2</summary>Có hai hướng: một từ khóa của <code>UNIQUE</code> (Postgres 15+), hoặc unique index trên biểu thức thay NULL bằng giá trị cố định.</details>
<details><summary>H3</summary><code>UNIQUE NULLS NOT DISTINCT (product_id, region)</code>, hoặc <code>CREATE UNIQUE INDEX … (product_id, coalesce(region, ''))</code>.</details>

## ex05 · Tag nhiều-nhiều
<details><summary>H1</summary>Bảng nối có PK ghép. Không phân biệt hoa/thường: unique trên biểu thức.</details>
<details><summary>H2</summary><code>CREATE UNIQUE INDEX … ON r01.tags (lower(name))</code>; <code>CHECK (name = btrim(name))</code>; FK phía sản phẩm <code>ON DELETE CASCADE</code>, phía tag để mặc định.</details>
<details><summary>H3</summary>PK <code>(product_id, tag_id)</code> chỉ phục vụ tìm theo <code>product_id</code>. Tìm theo tag cần thêm <code>CREATE INDEX … (tag_id)</code>.</details>

## ex06 · Số điện thoại chính
<details><summary>H1</summary>Chỉ những dòng <code>is_primary = true</code> cần duy nhất theo user.</details>
<details><summary>H2</summary>Unique index <b>partial</b>: <code>… (user_id) WHERE is_primary</code>.</details>
<details><summary>H3</summary>Thêm <code>UNIQUE (user_id, phone)</code> để chặn lưu trùng số.</details>

## ex07 · Doanh thu quý 1
<details><summary>H1</summary>Hai tổng khác nhau: một dùng giá trên dòng hàng, một dùng giá trên bảng sản phẩm.</details>
<details><summary>H2</summary>JOIN <code>order_items</code> và <code>products</code>; <code>sum(oi.unit_price * oi.quantity)</code> và <code>sum(p.price * oi.quantity)</code>. Tháng: <code>date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')</code>.</details>
<details><summary>H3</summary>Lọc <code>created_at &gt;= '2026-01-01 00:00+07' AND created_at &lt; '2026-04-01 00:00+07'</code> và <code>status NOT IN ('cancelled','refunded')</code>.</details>

## ex08 · Đối soát total_amount
<details><summary>H1</summary>Tính tổng dòng hàng cho từng đơn trước, rồi mới ghép với bảng đơn.</details>
<details><summary>H2</summary>Subquery <code>SELECT order_id, sum(quantity * unit_price) … GROUP BY order_id</code> rồi <code>LEFT JOIN</code>. Nếu JOIN trước rồi cộng, <code>shipping_fee</code> bị nhân theo số dòng hàng.</details>
<details><summary>H3</summary><code>coalesce(i.items_total, 0) + o.shipping_fee - o.discount_amount</code>; <code>ORDER BY abs(diff) DESC, id</code>.</details>

## ex09 · Mô hình phòng khám
<details><summary>H1</summary>Liệt kê "danh từ" trong đề (bệnh nhân, bác sĩ, chuyên khoa, lịch hẹn, dịch vụ) và quan hệ giữa chúng (1-n hay n-n).</details>
<details><summary>H2</summary>Các chỗ cần bảng riêng: số điện thoại (đa trị), bác sĩ–chuyên khoa (n-n), lịch hẹn–dịch vụ (n-n), lịch sử giá.</details>
<details><summary>H3</summary>"Hóa đơn cũ phải giữ nguyên" là dấu hiệu của snapshot: lưu giá lúc khám trên dòng hàng thay vì join về bảng giá hiện tại.</details>

## ex10 · Câu hỏi quy mô
<details><summary>H1</summary>Xem phần "Trigger for constraint …" trong output EXPLAIN ANALYZE.</details>
<details><summary>H2</summary>Mỗi FK trỏ tới <code>users</code> sinh một kiểm tra. Kiểm tra đó tìm trong bảng con theo cột FK.</details>
<details><summary>H3</summary>Không có index trên cột FK ở bảng con thì kiểm tra là Seq Scan bảng con.</details>
