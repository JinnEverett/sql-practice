# I07 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Đọc thuộc tính
<details><summary>H1</summary><code>-&gt;&gt;</code> cho text (không ngoặc kép), rồi ép kiểu cho số.</details>
<details><summary>H2</summary><code>(attributes-&gt;&gt;'weight_g')::int</code>.</details>
<details><summary>H3</summary>Key thiếu tự ra NULL, không cần CASE.</details>

## ex02 · Đếm theo màu
<details><summary>H1</summary>Gom theo <code>attributes-&gt;&gt;'color'</code>.</details>
<details><summary>H2</summary><code>coalesce(attributes-&gt;&gt;'color', '(không có)')</code>.</details>
<details><summary>H3</summary><code>WHERE is_active GROUP BY 1 ORDER BY n_products DESC, color</code>.</details>

## ex03 · Thiếu device
<details><summary>H1</summary>Toán tử <code>?</code> kiểm tra có key.</details>
<details><summary>H2</summary><code>count(*) FILTER (WHERE NOT properties ? 'device')</code>.</details>
<details><summary>H3</summary><code>round(100.0 * … / count(*), 2)</code>, <code>GROUP BY event_type</code>.</details>

## ex04 · Khám phá key
<details><summary>H1</summary><code>jsonb_object_keys</code> sinh một dòng cho mỗi key.</details>
<details><summary>H2</summary><code>FROM products, jsonb_object_keys(attributes) AS k GROUP BY k</code>.</details>
<details><summary>H3</summary><code>string_agg(DISTINCT jsonb_typeof(attributes-&gt;k), ', ')</code>.</details>

## ex05 · Nguồn traffic
<details><summary>H1</summary>Khách vãng lai có <code>user_id</code> NULL nhưng có <code>anonymous_id</code>.</details>
<details><summary>H2</summary><code>count(DISTINCT coalesce(user_id::text, anonymous_id))</code>.</details>
<details><summary>H3</summary><code>WHERE event_type = 'page_view' AND properties ? 'utm_source'</code>.</details>

## ex06 · JSON cho API
<details><summary>H1</summary><code>jsonb_build_object</code> cho đơn, <code>jsonb_agg(jsonb_build_object(…) ORDER BY line_no)</code> cho items.</details>
<details><summary>H2</summary>Items lấy bằng scalar subquery tương quan theo <code>o.id</code>.</details>
<details><summary>H3</summary>Key: <code>'line', oi.line_no, 'product_id', oi.product_id, 'qty', oi.quantity, 'price', oi.unit_price</code>.</details>

## ex07 · Đơn mua kèm
<details><summary>H1</summary>Gom product_id thành mảng, rồi lọc mảng "chứa" <code>{1,4}</code>.</details>
<details><summary>H2</summary><code>HAVING array_agg(product_id) @&gt; ARRAY[1, 4]::bigint[]</code>.</details>
<details><summary>H3</summary>Cột hiển thị: <code>array_agg(product_id ORDER BY product_id)</code>.</details>

## ex08 · Chuẩn hóa thuộc tính
<details><summary>H1</summary>Toán tử: <code>-</code> xóa key, <code>||</code> thêm key, <code>jsonb_strip_nulls</code> xóa key giá trị null.</details>
<details><summary>H2</summary><code>(attributes - 'weight_g') || jsonb_build_object('weight_kg', round((attributes-&gt;&gt;'weight_g')::numeric / 1000, 3))</code>.</details>
<details><summary>H3</summary>Bảo hành: <code>|| CASE WHEN attributes ? 'warranty_months' THEN '{}'::jsonb ELSE '{"warranty_months": 12}'::jsonb END</code>; bọc ngoài <code>jsonb_strip_nulls(…)</code>. Hoặc làm 3 câu UPDATE riêng.</details>

## ex09 · jsonpath
<details><summary>H1</summary><code>attributes @? '$ ? (điều kiện)'</code>.</details>
<details><summary>H2</summary>Trong jsonpath, <code>@</code> là object đang xét, <code>&amp;&amp;</code> là AND.</details>
<details><summary>H3</summary><code>'$ ? (@.weight_g &gt; 2000 &amp;&amp; @.warranty_months &gt;= 12)'</code>.</details>
