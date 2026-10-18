# O01 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Role chỉ đọc
<details><summary>H1</summary>Hai tầng quyền cần có: một trên schema, một trên bảng.</details>
<details><summary>H2</summary><code>CREATE ROLE … NOLOGIN; GRANT USAGE ON SCHEMA …; GRANT SELECT ON ALL TABLES IN SCHEMA … TO …;</code></details>
<details><summary>H3</summary>Không cần <code>REVOKE</code> gì khác: bảng mới tạo mặc định không có quyền cho ai ngoài chủ.</details>

## ex02 · Bảng mới sau migration
<details><summary>H1</summary><code>GRANT … ON ALL TABLES</code> chỉ nhìn thấy bảng đã tồn tại. Có một lệnh khai báo quyền cho đối tượng sẽ tạo sau.</details>
<details><summary>H2</summary><code>ALTER DEFAULT PRIVILEGES IN SCHEMA o01 GRANT SELECT ON TABLES TO o01_ro;</code></details>
<details><summary>H3</summary>Giữ cả <code>GRANT SELECT ON ALL TABLES</code> (cho bảng có sẵn) lẫn default privileges (cho bảng mới). Default áp cho bảng do role đang chạy lệnh tạo ra; migration chạy bằng role khác thì thêm <code>FOR ROLE</code>.</details>

## ex03 · Role cho ứng dụng
<details><summary>H1</summary>Quyền có thể cấp theo <strong>cột</strong>: <code>GRANT SELECT (c1, c2) ON bảng TO …</code>.</details>
<details><summary>H2</summary><code>CREATE ROLE o01_app LOGIN</code> (mặc định đã không superuser/createdb/createrole). Cần thêm <code>USAGE</code> trên schema.</details>
<details><summary>H3</summary>Ba lệnh GRANT: <code>SELECT (id, tenant_id, name, email)</code> trên customers; <code>SELECT, INSERT</code> trên orders; <code>UPDATE (status)</code> trên orders.</details>

## ex04 · View cho CSKH
<details><summary>H1</summary>Mặc định view chạy bằng quyền của chủ view: người đọc view không cần quyền trên bảng gốc.</details>
<details><summary>H2</summary>Đừng đặt <code>security_invoker = true</code> ở đây: nó đổi sang quyền người gọi.</details>
<details><summary>H3</summary><code>CREATE VIEW o01.v_customers_public AS SELECT id, name, tenant_id FROM o01.customers;</code> + <code>GRANT USAGE ON SCHEMA</code> + <code>GRANT SELECT ON</code> view.</details>

## ex05 · Chống SQL injection
<details><summary>H1</summary>Giá trị người dùng truyền bằng tham số của <code>EXECUTE</code>, tên cột thì không tham số hóa được.</details>
<details><summary>H2</summary><code>EXECUTE format('… WHERE c.email = $1 ORDER BY %I', p_order_by) USING p_email</code>; trước đó kiểm tra <code>p_order_by IN ('id','name','email')</code>.</details>
<details><summary>H3</summary><code>RAISE EXCEPTION '…' USING ERRCODE = 'invalid_parameter_value'</code> cho cột ngoài danh sách; <code>RETURN QUERY EXECUTE …</code> để trả bảng.</details>

## ex06 · Row Level Security
<details><summary>H1</summary>Hai bước: bật RLS trên bảng và tạo policy cho role ứng dụng.</details>
<details><summary>H2</summary><code>USING</code> lọc dòng đọc được, <code>WITH CHECK</code> chặn dòng ghi vào. Giá trị tenant: <code>current_setting('app.tenant_id', true)</code> (tham số thứ hai = không lỗi khi chưa đặt).</details>
<details><summary>H3</summary><code>nullif(current_setting('app.tenant_id', true), '')::int</code> xử lý cả trường hợp rỗng; policy <code>FOR ALL TO o01_tenant_app</code> với cả <code>USING</code> và <code>WITH CHECK</code> như nhau.</details>

## ex07 · Câu hỏi quy mô
<details><summary>H1</summary>Policy được ghép vào <code>WHERE</code> của mọi truy vấn. Điều kiện nào planner đẩy xuống thành <code>Index Cond</code>, điều kiện nào ẩn trong subplan?</details>
<details><summary>H2</summary>Đo dưới <code>SET LOCAL ROLE</code>; superuser bỏ qua RLS nên plan của nó không có điều kiện policy.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex07.md</code> sau khi đã tự đo.</details>
