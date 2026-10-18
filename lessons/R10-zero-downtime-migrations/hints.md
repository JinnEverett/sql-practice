# R10 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Thêm cột không viết lại
<details><summary>H1</summary>Postgres 11+ không viết lại bảng khi default là hằng.</details>
<details><summary>H2</summary>Một câu <code>ALTER TABLE … ADD COLUMN … NOT NULL DEFAULT 0</code> là đủ; đừng thêm cột nullable rồi UPDATE.</details>
<details><summary>H3</summary><code>ALTER TABLE r10.orders ADD COLUMN priority integer NOT NULL DEFAULT 0;</code></details>

## ex02 · NOT NULL an toàn
<details><summary>H1</summary>Cần một ràng buộc CHECK tương đương làm bước đệm.</details>
<details><summary>H2</summary>Bốn lệnh: <code>ADD CONSTRAINT … CHECK (…) NOT VALID</code> → <code>VALIDATE CONSTRAINT</code> → <code>SET NOT NULL</code> → <code>DROP CONSTRAINT</code>.</details>
<details><summary>H3</summary>Sau khi có CHECK đã validate, <code>SET NOT NULL</code> không phải quét bảng. Nhớ DROP CHECK ở cuối.</details>

## ex03 · Backfill theo lô
<details><summary>H1</summary>FUNCTION không COMMIT được bên trong; PROCEDURE thì được.</details>
<details><summary>H2</summary>Vòng <code>LOOP</code>: UPDATE tối đa <code>p_batch</code> dòng có <code>status_code IS NULL</code> (chọn bằng subquery <code>ORDER BY id LIMIT p_batch</code>), <code>GET DIAGNOSTICS n = ROW_COUNT</code>, <code>EXIT WHEN n = 0</code>, rồi <code>COMMIT</code>.</details>
<details><summary>H3</summary>Ánh xạ bằng <code>CASE status WHEN 'pending' THEN 1 … END</code>. Gọi bằng <code>CALL</code> ngoài khối transaction.</details>

## ex04 · Index INVALID
<details><summary>H1</summary>Thứ tự: dữ liệu vi phạm → index hỏng → index mới. Index hỏng vẫn chiếm tên.</details>
<details><summary>H2</summary>Xóa trùng bằng <code>DELETE … USING</code> so sánh <code>(updated_at, id)</code>; <code>DROP INDEX CONCURRENTLY</code>; <code>CREATE UNIQUE INDEX CONCURRENTLY</code>.</details>
<details><summary>H3</summary>Kiểm tra index hỏng: <code>SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE indrelid = 'r10.users'::regclass</code>.</details>

## ex05 · Kế hoạch bigint
<details><summary>H1</summary>Mỗi bước phải hoặc không viết lại bảng, hoặc không chặn ghi.</details>
<details><summary>H2</summary>Cột mới + trigger đồng bộ → backfill theo lô → unique index CONCURRENTLY + NOT NULL qua CHECK → hoán đổi trong transaction ngắn có lock_timeout → dọn.</details>
<details><summary>H3</summary>Bảng con: lặp cùng quy trình cho cột FK, FK mới thêm bằng NOT VALID + VALIDATE trước khi hoán đổi.</details>

## ex06 · Expand/contract
<details><summary>H1</summary>Trigger <code>BEFORE INSERT OR UPDATE</code> sửa <code>NEW</code> để hai cột luôn bằng nhau.</details>
<details><summary>H2</summary>INSERT: dùng <code>coalesce</code> để cột nào có giá trị thì chép sang cột kia. UPDATE: cột nào <b>khác OLD</b> thì kéo cột còn lại theo (dùng <code>IS DISTINCT FROM</code>).</details>
<details><summary>H3</summary>Backfill: <code>UPDATE r10.orders2 SET amount_vnd = total WHERE amount_vnd IS DISTINCT FROM total</code>.</details>

## ex07 · FK an toàn
<details><summary>H1</summary>Cùng ý tưởng với NOT NULL: thêm ràng buộc "chưa xác thực" rồi xác thực sau.</details>
<details><summary>H2</summary><code>ADD CONSTRAINT … FOREIGN KEY … NOT VALID</code> rồi <code>ALTER TABLE … VALIDATE CONSTRAINT …</code>.</details>
<details><summary>H3</summary>Đừng quên: Postgres không tự tạo index cho cột FK (thêm bằng <code>CREATE INDEX CONCURRENTLY</code> nếu cần).</details>

## ex08 · Hàng đợi khóa
<details><summary>H1</summary>ALTER chờ khóa thì chặn cả những truy vấn đến sau. Làm sao để nó chờ ít thôi?</details>
<details><summary>H2</summary><code>SET LOCAL lock_timeout = '200ms'</code>, bắt <code>lock_not_available</code>, <code>pg_sleep</code>, thử lại tối đa vài chục lần.</details>
<details><summary>H3</summary>Đặt <code>SET LOCAL</code> <b>bên trong</b> vòng lặp, ngay trước <code>ALTER TABLE</code>, vì sub-transaction bị rollback sẽ hoàn tác nó.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Lệnh nào chỉ sửa catalog, lệnh nào phải đọc/ghi mọi dòng?</details>
<details><summary>H2</summary>Mức chặn phụ thuộc loại khóa: SHARE chặn ghi nhưng cho đọc; ACCESS EXCLUSIVE chặn cả hai.</details>
<details><summary>H3</summary>Thời gian chặn ≠ thời gian chạy: <code>VALIDATE CONSTRAINT</code> chạy lâu nhưng không chặn ai.</details>
