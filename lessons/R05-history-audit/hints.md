# R05 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Soft delete
<details><summary>H1</summary>View lọc theo <code>deleted_at</code>. Unique chỉ nên áp dụng cho một tập con của dòng.</details>
<details><summary>H2</summary>Unique index <b>partial</b> trên biểu thức: <code>(lower(email)) WHERE deleted_at IS NULL</code>.</details>
<details><summary>H3</summary><code>CREATE VIEW r05.active_accounts AS SELECT id, email, name FROM r05.accounts WHERE deleted_at IS NULL;</code></details>

## ex02 · Audit trigger
<details><summary>H1</summary>Cần một hàm trigger và một lệnh <code>CREATE TRIGGER</code> mức dòng (<code>FOR EACH ROW</code>).</details>
<details><summary>H2</summary>Trong hàm: <code>TG_OP</code> cho biết thao tác; <code>to_jsonb(OLD)</code>, <code>to_jsonb(NEW)</code> cho cả hàng. Ba nhánh: INSERT (chỉ NEW), UPDATE (cả hai), DELETE (chỉ OLD).</details>
<details><summary>H3</summary><code>AFTER INSERT OR UPDATE OR DELETE ON r05.products FOR EACH ROW</code>; hàm kết thúc bằng <code>RETURN NULL</code>.</details>

## ex03 · Audit gọn
<details><summary>H1</summary>Điều kiện "có thay đổi" đặt ở đâu để trigger không chạy khi không cần?</details>
<details><summary>H2</summary><code>WHEN (OLD.* IS DISTINCT FROM NEW.*)</code> trong <code>CREATE TRIGGER</code>. Cần tách trigger UPDATE khỏi trigger INSERT/DELETE vì OLD/NEW không tồn tại ở mọi thao tác.</details>
<details><summary>H3</summary>Diff: <code>jsonb_each(to_jsonb(OLD)) o JOIN jsonb_each(to_jsonb(NEW)) n USING (key) WHERE o.value IS DISTINCT FROM n.value</code>, gom bằng <code>jsonb_object_agg(key, jsonb_build_object('old', o.value, 'new', n.value))</code>.</details>

## ex04 · Trạng thái tại thời điểm T
<details><summary>H1</summary>Với mỗi sản phẩm, sự kiện nào quyết định trạng thái tại T?</details>
<details><summary>H2</summary><code>DISTINCT ON (row_id) … WHERE table_name = 'products' AND changed_at &lt;= T ORDER BY row_id, changed_at DESC, id DESC</code>.</details>
<details><summary>H3</summary>Bỏ sản phẩm đã xóa bằng <code>WHERE op &lt;&gt; 'DELETE'</code> ở truy vấn <b>ngoài</b> (sau khi đã chọn sự kiện cuối).</details>

## ex05 · SCD2
<details><summary>H1</summary>Mỗi thời điểm phải khớp đúng một khoảng. Khoảng nào đóng, khoảng nào mở?</details>
<details><summary>H2</summary><code>ordered_at &gt;= valid_from AND ordered_at &lt; coalesce(valid_to, 'infinity')</code>, <code>LEFT JOIN</code> để giữ đơn chưa có giá.</details>
<details><summary>H3</summary><code>qty * ph.price</code> cho thành tiền (NULL khi chưa có giá). Đừng dùng <code>BETWEEN</code>.</details>

## ex06 · Đổi giá nguyên tử
<details><summary>H1</summary>CTE có thể chứa <code>UPDATE … RETURNING</code> và câu chính dùng kết quả đó.</details>
<details><summary>H2</summary><code>WITH closed AS (UPDATE … SET valid_to = now() WHERE product_id = 1 AND valid_to IS NULL RETURNING product_id) INSERT …</code></details>
<details><summary>H3</summary><code>INSERT INTO r05.price_history (product_id, price, valid_from, valid_to) SELECT product_id, 160, now(), NULL FROM closed</code>.</details>

## ex07 · Giá chồng thời gian
<details><summary>H1</summary>Hai việc, theo thứ tự: sửa dữ liệu rồi thêm ràng buộc. Ràng buộc nào so sánh "khoảng chồng nhau"?</details>
<details><summary>H2</summary>Sửa: <code>lead(valid_from) OVER (PARTITION BY product_id ORDER BY valid_from)</code> cho thời điểm bắt đầu của dòng kế tiếp. Ràng buộc: <code>EXCLUDE USING gist</code>.</details>
<details><summary>H3</summary><code>EXCLUDE USING gist (product_id WITH =, tstzrange(valid_from, valid_to) WITH &amp;&amp;)</code>; chỉ cắt khi <code>next_from &lt; coalesce(valid_to, 'infinity')</code>.</details>

## ex08 · Đơn sau khi xóa
<details><summary>H1</summary>Cần hai con số khác nhau từ cùng nhóm đơn: đơn sau xóa và tất cả đơn.</details>
<details><summary>H2</summary><code>count(o.id) FILTER (WHERE o.created_at &gt;= u.deleted_at)</code> và <code>count(o.id)</code> trong cùng một <code>GROUP BY u.id</code>.</details>
<details><summary>H3</summary>Lọc <code>u.deleted_at IS NOT NULL</code> ở <code>WHERE</code>; lọc user có đơn sau xóa bằng <code>HAVING</code> với cùng biểu thức <code>FILTER</code>.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Trigger ROW-level chạy bao nhiêu lần cho một lệnh UPDATE toàn bảng?</details>
<details><summary>H2</summary>Mỗi lần chạy chèn một dòng vào bảng audit: cộng thêm ghi heap, ghi index PK, ghi WAL.</details>
<details><summary>H3</summary>Giảm chi phí: tắt trigger khi backfill kèm một dòng audit mức câu lệnh; chỉ audit cột quan trọng; partition + retention cho bảng audit.</details>
