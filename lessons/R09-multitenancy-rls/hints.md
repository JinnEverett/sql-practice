# R09 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · FK chéo tenant
<details><summary>H1</summary>FK hiện tại chỉ so sánh <code>customer_id</code>. Cần so sánh cả <code>tenant_id</code>.</details>
<details><summary>H2</summary>FK ghép <code>(customer_id, tenant_id) → customers (id, tenant_id)</code>. Postgres đòi bộ cột được tham chiếu phải có UNIQUE hoặc PK.</details>
<details><summary>H3</summary>Thêm <code>UNIQUE (id, tenant_id)</code> trên <code>customers</code> trước (luôn đúng vì <code>id</code> đã là PK).</details>

## ex02 · RLS cô lập
<details><summary>H1</summary>Hai bước: bật RLS cho bảng, rồi tạo policy. Tenant hiện tại lấy từ biến phiên <code>app.tenant_id</code>.</details>
<details><summary>H2</summary><code>CREATE POLICY … USING (…) WITH CHECK (…)</code>; <code>USING</code> cho phần nhìn thấy, <code>WITH CHECK</code> cho phần ghi.</details>
<details><summary>H3</summary>Biểu thức: <code>tenant_id = nullif(current_setting('app.tenant_id', true), '')::int</code>. Test bằng <code>SET ROLE r09_app</code>, không bằng superuser.</details>

## ex03 · Fail closed
<details><summary>H1</summary>Hai lỗi khác nhau: biến chưa tồn tại, và biến tồn tại nhưng rỗng. Mỗi lỗi có một cách xử lý riêng.</details>
<details><summary>H2</summary><code>current_setting('…', true)</code> trả NULL thay vì lỗi; <code>nullif(…, '')</code> đổi chuỗi rỗng thành NULL trước khi ép kiểu.</details>
<details><summary>H3</summary><code>ALTER POLICY tenant_isolation ON r09.notes USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);</code> (không có WITH CHECK riêng thì mặc định dùng lại USING).</details>

## ex04 · View và RLS
<details><summary>H1</summary>View chạy với quyền của ai?</details>
<details><summary>H2</summary>Có một tùy chọn của view để nó chạy với quyền người gọi (Postgres 15+).</details>
<details><summary>H3</summary><code>ALTER VIEW r09.payment_totals SET (security_invoker = true);</code></details>

## ex05 · Role hỗ trợ
<details><summary>H1</summary>Policy cùng loại lệnh được OR với nhau. Bạn cần một policy dành riêng cho role hỗ trợ.</details>
<details><summary>H2</summary><code>CREATE POLICY … ON r09.payments FOR SELECT TO r09_support USING (true)</code>.</details>
<details><summary>H3</summary>Nếu quên <code>TO r09_support</code>, policy áp dụng cho PUBLIC và ứng dụng thường thấy hết.</details>

## ex06 · Provision tenant
<details><summary>H1</summary>Tên schema do người dùng cung cấp → phải kiểm tra định dạng và trích dẫn định danh, không nối chuỗi.</details>
<details><summary>H2</summary><code>IF p_slug !~ '^[a-z][a-z0-9_]{0,40}$' THEN RAISE EXCEPTION … USING ERRCODE = '22023'</code>; <code>EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', …)</code>.</details>
<details><summary>H3</summary><code>CREATE TABLE IF NOT EXISTS %I.invoices (LIKE r09.tpl_invoices INCLUDING ALL)</code>; rồi hai lệnh <code>GRANT</code> bằng <code>format</code>.</details>

## ex07 · Câu hỏi quy mô
<details><summary>H1</summary>RLS thêm một điều kiện WHERE. Điều kiện đó có dùng được index không?</details>
<details><summary>H2</summary>So sánh plan (a) và (b): giống nhau thì không có chi phí RLS riêng.</details>
<details><summary>H3</summary>Hàm VOLATILE trong policy: planner không coi nó là hằng, nên không dùng được cho điều kiện index.</details>
