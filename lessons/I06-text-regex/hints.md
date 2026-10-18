# I06 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Tìm tai nghe
<details><summary>H1</summary>Toán tử LIKE không phân biệt hoa thường.</details>
<details><summary>H2</summary><code>name ILIKE '%…%'</code>.</details>
<details><summary>H3</summary><code>WHERE is_active AND name ILIKE '%tai nghe%' ORDER BY id</code>.</details>

## ex02 · Định dạng số điện thoại
<details><summary>H1</summary>Toán tử <code>~</code> với regex neo <code>^…$</code>, đặt trong CASE.</details>
<details><summary>H2</summary><code>'^0\d{9}$'</code> và <code>'^\+84\s\d{9}$'</code> (dấu + phải escape).</details>
<details><summary>H3</summary>Nhánh đầu: <code>WHEN phone IS NULL THEN '(trống)'</code>; <code>GROUP BY 1 ORDER BY n_users DESC</code>.</details>

## ex03 · E.164
<details><summary>H1</summary>Bỏ hết ký tự không phải số trước, rồi bỏ tiền tố.</details>
<details><summary>H2</summary><code>regexp_replace(phone, '\D', '', 'g')</code> → chỉ còn số; tiếp <code>regexp_replace(…, '^(84|0)', '')</code>.</details>
<details><summary>H3</summary><code>'+84' || regexp_replace(regexp_replace(phone, '\D', '', 'g'), '^(84|0)', '')</code>.</details>

## ex04 · Gộp có dấu / không dấu
<details><summary>H1</summary><code>unaccent()</code> bỏ dấu tiếng Việt.</details>
<details><summary>H2</summary>Gom theo <code>lower(trim(unaccent(properties-&gt;&gt;'query')))</code>.</details>
<details><summary>H3</summary><code>count(DISTINCT properties-&gt;&gt;'query') AS n_variants</code>.</details>

## ex05 · Tên phổ biến
<details><summary>H1</summary>Lấy từ cuối cùng bằng regex có neo <code>$</code>.</details>
<details><summary>H2</summary><code>substring(trim(full_name) FROM '(\S+)$')</code>.</details>
<details><summary>H3</summary><code>GROUP BY 1 ORDER BY n_users DESC, ten LIMIT 10</code>; loại <code>full_name IS NULL</code>.</details>

## ex06 · Tóm tắt đơn hàng
<details><summary>H1</summary><code>string_agg(…, ', ' ORDER BY …)</code>.</details>
<details><summary>H2</summary>Phần tử: <code>p.name || ' × ' || oi.quantity</code>.</details>
<details><summary>H3</summary><code>order_items JOIN products … WHERE oi.order_id &lt;= 5 GROUP BY oi.order_id</code>, <code>ORDER BY oi.line_no</code> trong string_agg.</details>

## ex07 · Email cần làm sạch
<details><summary>H1</summary>So email với dạng đã chuẩn hóa của chính nó.</details>
<details><summary>H2</summary>Có chữ hoa: <code>email &lt;&gt; lower(email)</code>. Thừa khoảng trắng: <code>email &lt;&gt; trim(email)</code>.</details>
<details><summary>H3</summary>CASE xét "cả hai" trước tiên; WHERE là OR của hai điều kiện.</details>

## ex08 · Slug
<details><summary>H1</summary>Bỏ dấu → chữ thường → thay cụm ký tự lạ → cắt '-' hai đầu.</details>
<details><summary>H2</summary><code>regexp_replace(lower(unaccent(name)), '[^a-z0-9]+', '-', 'g')</code>.</details>
<details><summary>H3</summary>Bọc <code>trim(BOTH '-' FROM …)</code>; WHERE so <code>slug &lt;&gt; &lt;biểu thức đó&gt;</code>.</details>

## ex09 · Từ được tìm nhiều nhất
<details><summary>H1</summary>Hàm biến một chuỗi thành nhiều dòng: <code>regexp_split_to_table</code>.</details>
<details><summary>H2</summary><code>FROM events, regexp_split_to_table(lower(unaccent(trim(properties-&gt;&gt;'query'))), '\s+') AS token</code>.</details>
<details><summary>H3</summary><code>WHERE event_type = 'search' GROUP BY token ORDER BY n DESC, token LIMIT 10</code>.</details>
