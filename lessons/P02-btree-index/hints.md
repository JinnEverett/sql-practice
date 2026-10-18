# P02 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Đơn của một khách
<details><summary>H1</summary>Query lọc equality trên một cột: index trên cột đó.</details>
<details><summary>H2</summary><code>CREATE INDEX ON orders (…)</code> với cột có trong <code>WHERE</code>.</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (user_id);</code></details>

## ex02 · 5 đơn gần nhất
<details><summary>H1</summary>Index lưu key đã sắp xếp: nếu thứ tự index khớp <code>ORDER BY</code> thì không cần Sort.</details>
<details><summary>H2</summary>Index composite: cột equality trước, cột ORDER BY sau. Index có thể được đọc ngược.</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (user_id, created_at);</code></details>

## ex03 · Một index cho ba query
<details><summary>H1</summary>Cả ba có chung một cột equality. Cột đó nên đứng đầu để mọi query dùng được tiền tố.</details>
<details><summary>H2</summary>Sau cột đầu, thêm các cột còn lại theo kiểu "equality rồi range". Thử cả hai thứ tự của <code>status</code> và <code>created_at</code>.</details>
<details><summary>H3</summary><code>(user_id, created_at)</code> là đủ; <code>(user_id, status, created_at)</code> cũng được. <code>(created_at, user_id)</code> thì không (query a bỏ lỡ).</details>

## ex04 · Covering
<details><summary>H1</summary>Index Only Scan cần mọi cột query dùng đều có trong index.</details>
<details><summary>H2</summary>Cột lọc là key; cột chỉ để tính <code>sum</code> đặt ở <code>INCLUDE</code> hoặc cuối key.</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (user_id) INCLUDE (total_amount);</code></details>

## ex05 · Hàng đợi đơn chưa xử lý
<details><summary>H1</summary>Chỉ một phần nhỏ của bảng (<code>status</code> chưa xong) được query quan tâm. Không cần index toàn bảng.</details>
<details><summary>H2</summary>Partial index trên <code>created_at</code> (cột ORDER BY) với <code>WHERE</code> bao trùm điều kiện của query.</details>
<details><summary>H3</summary><code>… WHERE status IN ('pending','paid','shipped')</code> hoặc đúng <code>IN ('pending','paid')</code>. Điều kiện chỉ <code>= 'pending'</code> thì planner không dùng được.</details>

## ex06 · Ngày sale
<details><summary>H1</summary>Cột bị bọc trong biểu thức thì index trên cột gốc vô dụng.</details>
<details><summary>H2</summary>Tạo index trên biểu thức, viết giống hệt biểu thức trong query, thêm một cặp ngoặc quanh biểu thức.</details>
<details><summary>H3</summary><code>CREATE INDEX ON orders (((created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date));</code> Lưu ý <code>created_at::date</code> không tạo được vì không IMMUTABLE.</details>

## ex07 · Tiền tố email
<details><summary>H1</summary>Vì sao <code>LIKE 'abc%'</code> không dùng được index thường? Xem collation của DB.</details>
<details><summary>H2</summary>Có operator class riêng cho so sánh theo byte.</details>
<details><summary>H3</summary><code>CREATE INDEX ON users (email text_pattern_ops);</code></details>

## ex08 · Quá nhiều index
<details><summary>H1</summary>Xem <code>pg_indexes</code>: có index nào là tiền tố của index khác, hoặc trùng hệt?</details>
<details><summary>H2</summary>Một index dài <code>(user_id, created_at, status)</code> phục vụ cả ba query về <code>user_id</code>. Query 4 cần index khác.</details>
<details><summary>H3</summary>Bỏ <code>ord_user</code>, <code>ord_user_dup</code>, <code>ord_user_created</code>. Giữ <code>ord_user_created_stat</code> và <code>ord_status</code>.</details>

## ex09 · Index lớn lên thế nào
<details><summary>H1</summary>Mỗi page index chứa hàng trăm key; mỗi tầng nhân số key lên hàng trăm lần.</details>
<details><summary>H2</summary>bytes/key của PK ≈ 22–25 B; level ở 1M là 2. Bao nhiêu leaf cho 10M? Root trỏ được bao nhiêu internal page?</details>
<details><summary>H3</summary>Số buffers = level + 1 (index) + 1 (heap). So với Seq Scan: số page heap tăng tuyến tính theo N.</details>
