# R08 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Lost update
<details><summary>H1</summary>Hai session cần cùng mở transaction trước khi một bên commit.</details>
<details><summary>H2</summary>Cách (a): cả hai <code>SELECT n</code> được 0, rồi mỗi bên <code>UPDATE … SET n = 1</code>. Cách (b): bên thứ hai sẽ bị chặn cho tới khi bên thứ nhất commit.</details>
<details><summary>H3</summary>Chạy <code>solutions/ex01.sql</code> để xem kết quả tự động, rồi tự làm lại bằng hai cửa sổ <code>psql</code>.</details>

## ex02 · Oversell
<details><summary>H1</summary>Gộp "kiểm tra đủ hàng" và "trừ hàng" vào một câu lệnh.</details>
<details><summary>H2</summary><code>UPDATE r08.products SET stock = stock - p_qty WHERE id = p_product AND stock &gt;= p_qty;</code> rồi <code>IF NOT FOUND THEN RETURN false</code>.</details>
<details><summary>H3</summary>Chỉ khi UPDATE thành công mới <code>INSERT INTO r08.orders …</code> rồi <code>RETURN true</code>. Cách khác: <code>SELECT stock … FOR UPDATE</code> trước khi kiểm tra.</details>

## ex03 · Optimistic locking
<details><summary>H1</summary>Điều kiện "chưa ai sửa" nằm ở đâu để kiểm tra và ghi là một bước?</details>
<details><summary>H2</summary><code>UPDATE … SET price = …, version = version + 1 WHERE id = … AND version = p_expected_version</code>.</details>
<details><summary>H3</summary><code>RETURN FOUND;</code> cho biết có dòng nào bị sửa không.</details>

## ex04 · Double booking
<details><summary>H1</summary>Unique chỉ so sánh bằng. Cần ràng buộc so sánh "chồng nhau" (<code>&amp;&amp;</code>).</details>
<details><summary>H2</summary><code>EXCLUDE USING gist (room_id WITH =, during WITH &amp;&amp;)</code> (extension <code>btree_gist</code> đã có sẵn). Thêm <code>WHERE (status = 'confirmed')</code> để bỏ qua đặt chỗ đã hủy.</details>
<details><summary>H3</summary><code>ALTER TABLE r08.bookings ADD CONSTRAINT … EXCLUDE USING gist (…) WHERE (…);</code></details>

## ex05 · Write skew
<details><summary>H1</summary>Hai request sửa hai dòng khác nhau nên khóa dòng của chính mình không đủ. Cần khóa thứ mà cả hai cùng đọc.</details>
<details><summary>H2</summary>Khóa mọi dòng đang trực trước khi đếm: <code>PERFORM 1 FROM r08.doctors WHERE on_call FOR UPDATE;</code>. Request sau sẽ chờ rồi đếm lại.</details>
<details><summary>H3</summary>Sau khi khóa: đếm; nếu <code>&lt;= 1</code> thì <code>RETURN false</code>; không thì <code>UPDATE … SET on_call = false WHERE id = p_doc AND on_call</code> và <code>RETURN FOUND</code>. Cách khác: <code>pg_advisory_xact_lock(hashtext('…'))</code>.</details>

## ex06 · Deadlock
<details><summary>H1</summary>Vòng chờ xảy ra vì A khóa (1 rồi 2), B khóa (2 rồi 1). Hai bên cần khóa theo cùng một thứ tự.</details>
<details><summary>H2</summary>Khóa cả hai tài khoản ngay đầu hàm theo <code>ORDER BY id</code>: <code>PERFORM 1 FROM r08.accounts WHERE id IN (p_from, p_to) ORDER BY id FOR UPDATE;</code></details>
<details><summary>H3</summary>Các lệnh <code>UPDATE</code> và <code>pg_sleep(0.5)</code> giữ nguyên sau bước khóa. Dùng <code>CREATE OR REPLACE FUNCTION</code>.</details>

## ex07 · SERIALIZABLE
<details><summary>H1</summary><code>BEGIN ISOLATION LEVEL SERIALIZABLE</code> ở cả hai session.</details>
<details><summary>H2</summary>Lỗi xuất hiện ở lúc <code>COMMIT</code> (hoặc UPDATE) của session thứ hai: SQLSTATE <code>40001</code>.</details>
<details><summary>H3</summary>Ứng dụng chạy lại cả giao dịch từ đầu; lần chạy lại thấy dữ liệu mới nên tự từ chối.</details>

## ex08 · Dòng nóng
<details><summary>H1</summary>Bao nhiêu giao dịch có thể cùng ghi một dòng tại một thời điểm?</details>
<details><summary>H2</summary>Với 16 dòng và chọn dòng ngẫu nhiên, xác suất hai client trùng dòng giảm mạnh.</details>
<details><summary>H3</summary>Cách khác: bảng append-only (INSERT mỗi sự kiện) cộng dồn bằng job nền; bộ đếm ngoài database.</details>
