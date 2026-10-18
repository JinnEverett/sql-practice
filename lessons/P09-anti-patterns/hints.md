# P09 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Đơn của một ngày
<details><summary>H1</summary>Cột bị bọc trong phép cast nên index trên cột vô dụng.</details>
<details><summary>H2</summary>Viết điều kiện thành khoảng trên chính cột (đầu ngày ≤ x &lt; đầu ngày kế).</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (created_at);</code> và <code>created_at &gt;= '2026-09-11' AND created_at &lt; '2026-09-12'</code>.</details>

## ex02 · Tham số sai kiểu
<details><summary>H1</summary>Đưa hằng về kiểu của cột thay vì đưa cột về kiểu của hằng.</details>
<details><summary>H2</summary><code>user_id = 4242</code> (integer) và index trên <code>user_id</code>.</details>
<details><summary>H3</summary>Nếu không sửa được query: <code>CREATE INDEX ON orders ((user_id::text))</code>.</details>

## ex03 · Mã đơn hoặc email
<details><summary>H1</summary>OR giữa hai bảng không tách được. Tách thành hai truy vấn.</details>
<details><summary>H2</summary>Nhánh 1 tra PK <code>orders</code>; nhánh 2 tra <code>users(email)</code> rồi <code>orders(user_id)</code>; ghép bằng UNION.</details>
<details><summary>H3</summary>Index <code>users(email)</code> và <code>orders(user_id)</code>; <code>SELECT id FROM orders WHERE id = 123456 UNION SELECT o.id FROM users u JOIN orders o ON o.user_id = u.id WHERE u.email = '…'</code>.</details>

## ex04 · Trang 45 001
<details><summary>H1</summary>Thay vì "bỏ N dòng đầu", hỏi "những dòng sau dòng cuối của trang trước".</details>
<details><summary>H2</summary>So sánh theo cặp <code>(created_at, id) &lt; (…, …)</code> với index khớp thứ tự <code>ORDER BY</code>.</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (created_at DESC, id DESC)</code>; <code>WHERE (created_at, id) &lt; ('2025-02-21 05:57:20.456226+00', 100001) ORDER BY created_at DESC, id DESC LIMIT 20</code>.</details>

## ex05 · SELECT *
<details><summary>H1</summary>Cột nào đang nặng? Có cần nó cho màn hình này không?</details>
<details><summary>H2</summary>Liệt kê cột cần: <code>id, title</code>.</details>
<details><summary>H3</summary><code>SELECT id, title FROM p09.docs WHERE kind = 'long'</code>.</details>

## ex06 · Có N kết quả
<details><summary>H1</summary>Bạn chỉ cần biết "có hơn 1000 không", không cần số chính xác.</details>
<details><summary>H2</summary>Đếm trên subquery giới hạn số dòng.</details>
<details><summary>H3</summary><code>SELECT count(*) FROM (SELECT 1 FROM events WHERE event_type = 'search' LIMIT 1001) t</code>.</details>

## ex07 · N+1
<details><summary>H1</summary>Cần "dòng đầu tiên theo thứ tự" cho mỗi khách trong một câu.</details>
<details><summary>H2</summary><code>CROSS JOIN LATERAL (… LIMIT 1)</code> hoặc <code>DISTINCT ON (user_id)</code>; cần index <code>(user_id, created_at DESC, id DESC)</code>.</details>
<details><summary>H3</summary><code>FROM generate_series(1,50) u(id) CROSS JOIN LATERAL (SELECT id, created_at FROM orders WHERE user_id = u.id ORDER BY created_at DESC, id DESC LIMIT 1) o</code>.</details>

## ex08 · Khách chưa từng mua
<details><summary>H1</summary>Có phép "không tồn tại dòng khớp" đúng nghĩa và không nhạy NULL.</details>
<details><summary>H2</summary><code>NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)</code> hoặc LEFT JOIN + IS NULL.</details>
<details><summary>H3</summary>Đáp án 960 khách; plan là Hash Right Anti Join.</details>

## ex09 · OFFSET sâu
<details><summary>H1</summary>OFFSET phải sinh và bỏ N dòng đầu.</details>
<details><summary>H2</summary>Chi phí tỉ lệ với offset; keyset là hằng số.</details>
<details><summary>H3</summary>Tạo index trong transaction rồi ROLLBACK để không làm bẩn <code>shop_m</code>.</details>
