# I09 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · View đơn hàng theo ngày VN
<details><summary>H1</summary><code>CREATE VIEW … AS SELECT …</code>. Ngày theo giờ VN: chuyển <code>timestamptz</code> sang giờ VN trước, rồi mới ép <code>date</code>.</details>
<details><summary>H2</summary><code>(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date</code>. Nối <code>orders</code> với <code>customers</code> để lấy tên.</details>
<details><summary>H3</summary>Tên cột đặt bằng <code>AS</code> đúng 5 tên và đúng thứ tự trong đề; <code>WHERE o.status &lt;&gt; 'cancelled'</code>.</details>

## ex02 · Hàm VAT
<details><summary>H1</summary>Hàm chỉ tính toán từ đối số, không đọc bảng: chọn nhãn độ ổn định nghiêm ngặt nhất đúng được.</details>
<details><summary>H2</summary><code>LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT round(…, 0) $$</code>. Tham số thứ hai có <code>DEFAULT 0.08</code>.</details>
<details><summary>H3</summary><code>round(amount * (1 + rate), 0)</code>.</details>

## ex03 · View ghi được
<details><summary>H1</summary>Có một mệnh đề cuối <code>CREATE VIEW</code> kiểm tra dòng sau khi ghi còn thỏa điều kiện của view.</details>
<details><summary>H2</summary><code>… WHERE status = 'active' WITH CHECK OPTION</code>.</details>
<details><summary>H3</summary>View phải chọn cả cột <code>status</code> để <code>INSERT</code> qua view đặt được giá trị đó.</details>

## ex04 · Materialized view
<details><summary>H1</summary><code>CREATE MATERIALIZED VIEW</code>. <code>REFRESH … CONCURRENTLY</code> đòi hỏi một điều kiện trên index của matview.</details>
<details><summary>H2</summary>Cần một <strong>unique</strong> index (không partial, không biểu thức) trên cột xác định mỗi dòng: ở đây là <code>day</code>.</details>
<details><summary>H3</summary><code>CREATE UNIQUE INDEX ON i09.mv_daily_revenue (day);</code> ngay sau khi tạo matview.</details>

## ex05 · apply_discount
<details><summary>H1</summary><code>UPDATE … RETURNING total INTO v</code>, rồi dùng biến <code>FOUND</code> để biết có dòng nào được cập nhật không.</details>
<details><summary>H2</summary>Kiểm tra <code>p_pct</code> trước khi <code>UPDATE</code>. Điều kiện trạng thái đặt trong <code>WHERE</code> của <code>UPDATE</code> để một câu lệnh vừa tìm vừa sửa.</details>
<details><summary>H3</summary><code>RAISE EXCEPTION '…' USING ERRCODE = 'invalid_parameter_value'</code> và <code>'no_data_found'</code>. Giảm giá: <code>round(total * (1 - p_pct / 100), 2)</code>.</details>

## ex06 · Trigger lịch sử giá
<details><summary>H1</summary>Cần hai thứ: một hàm <code>RETURNS trigger</code> và một <code>CREATE TRIGGER</code>. Thời điểm và mức nào để thấy cả giá cũ lẫn giá mới của từng dòng?</details>
<details><summary>H2</summary><code>AFTER UPDATE OF price ON i09.products FOR EACH ROW WHEN (OLD.price IS DISTINCT FROM NEW.price)</code>.</details>
<details><summary>H3</summary>Thân hàm: <code>INSERT INTO i09.price_history (product_id, old_price, new_price) VALUES (OLD.id, OLD.price, NEW.price); RETURN NULL;</code></details>

## ex07 · Kho âm
<details><summary>H1</summary>Trigger <code>BEFORE INSERT OR DELETE … FOR EACH ROW</code>; dùng <code>TG_OP</code> để phân biệt. Đừng "SELECT rồi UPDATE": hai session sẽ cùng thấy hàng còn.</details>
<details><summary>H2</summary>Một câu <code>UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id AND stock &gt;= NEW.quantity</code> vừa kiểm tra vừa trừ (và khóa dòng). Không có dòng nào cập nhật (<code>NOT FOUND</code>) → ném lỗi.</details>
<details><summary>H3</summary><code>RAISE EXCEPTION '…' USING ERRCODE = 'check_violation'</code>; INSERT trả <code>RETURN NEW</code>; DELETE cộng lại <code>OLD.quantity</code> và <code>RETURN OLD</code>.</details>

## ex08 · Thêm cột vào view
<details><summary>H1</summary>Có một dạng của <code>CREATE VIEW</code> giữ nguyên các view phụ thuộc. Nó có luật về vị trí cột mới.</details>
<details><summary>H2</summary><code>CREATE OR REPLACE VIEW</code>: giữ nguyên tên, kiểu và thứ tự các cột cũ, cột mới đặt <strong>cuối</strong>.</details>
<details><summary>H3</summary><code>SELECT o.id AS order_id, c.name AS customer_name, o.total, o.status FROM …</code> (cùng phép nối như định nghĩa cũ).</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Matview là một bảng nhỏ (một dòng mỗi ngày): đọc theo <code>day</code> với unique index là O(log n) trên vài trăm dòng. Còn "view" phải quét lại cả bảng.</details>
<details><summary>H2</summary>Trigger ROW chạy 1 lần mỗi dòng: đọc <code>Triggers</code> ở cuối <code>EXPLAIN ANALYZE</code> (số lần gọi, thời gian) khi bảng có trigger.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex09.md</code> sau khi đã tự đo.</details>
