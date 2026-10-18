# O01 · Security: role, GRANT, least privilege, RLS, SQL injection

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab`, schema `o01` (`setup.sql` dựng dữ liệu và xóa các role của bài nếu đã có).

## Mục tiêu: sau buổi này bạn làm được
- Tạo role đúng cách (role nhóm `NOLOGIN` + role đăng nhập), cấp quyền theo từng tầng: schema → bảng → cột.
- Dùng `ALTER DEFAULT PRIVILEGES` để bảng tạo sau không bị "quên cấp quyền".
- Áp dụng least privilege cho một ứng dụng: chỉ đúng quyền cần, giấu cột nhạy cảm.
- Phơi dữ liệu một phần qua view; hiểu `security_invoker`.
- Cô lập multi-tenant bằng Row Level Security (RLS).
- Phòng SQL injection: tham số hóa giá trị, whitelist định danh.

---

## 1. Role và các tầng quyền
```sql
CREATE ROLE o01_ro NOLOGIN;                       -- role "nhóm quyền": không đăng nhập
GRANT USAGE ON SCHEMA o01 TO o01_ro;              -- quyền đi vào schema
GRANT SELECT ON ALL TABLES IN SCHEMA o01 TO o01_ro;   -- quyền trên bảng ĐÃ có
CREATE ROLE alice LOGIN PASSWORD '…';             -- người/app đăng nhập
GRANT o01_ro TO alice;                            -- alice thừa hưởng quyền của o01_ro
```
- Trong Postgres "user" và "group" đều là role. `LOGIN` cho phép đăng nhập; `GRANT role TO role` chuyển quyền.
- Truy cập `o01.orders` cần **cả hai**: `USAGE` trên schema và `SELECT` trên bảng. Thiếu một trong hai → `42501 permission denied`.
- Quyền theo cột: `GRANT SELECT (id, name) ON customers TO r` và `GRANT UPDATE (status) ON orders TO r`. Khi đó `SELECT *` bị từ chối (vì `*` gồm cả cột cấm); ứng dụng phải liệt kê cột.
- `PUBLIC` là "mọi role". Đừng cấp quyền cho PUBLIC. Từ Postgres 15, role thường không còn `CREATE` trên schema `public` mặc định.
- `REVOKE` thu hồi; `\dp tên_bảng` và `\ddp` xem quyền và default privileges; `has_table_privilege('role', 'bảng', 'SELECT')` kiểm tra bằng SQL.
- Chủ bảng (owner) và superuser có mọi quyền. Ứng dụng **không bao giờ** nên kết nối bằng owner hay superuser: một lỗ hổng sẽ thành quyền `DROP`.

## 2. Default privileges
`GRANT … ON ALL TABLES` chỉ áp cho bảng có sẵn. Bảng tạo sau (migration) thì không:
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA o01 GRANT SELECT ON TABLES TO o01_ro;
-- áp cho bảng do role đang chạy lệnh tạo. Migration chạy bằng role khác thì thêm FOR ROLE migrator
```
Triệu chứng kinh điển: "sau lần deploy, báo cáo lỗi `permission denied for table …`" vì bảng mới không có GRANT.

## 3. View để phơi một phần dữ liệu
Mặc định view chạy với quyền của **chủ view**, nên cấp `SELECT` trên view mà không cấp trên bảng gốc là cách cho nhóm hỗ trợ xem `id, name` mà không thấy `password_hash`. `WITH (security_invoker = true)` đổi sang quyền người gọi (cần khi muốn RLS của bảng gốc áp cho người gọi), lúc đó người gọi phải có quyền trên bảng gốc.

## 4. Row Level Security
```sql
ALTER TABLE o01.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON o01.orders FOR ALL TO o01_tenant_app
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
-- ứng dụng, đầu mỗi transaction:
SELECT set_config('app.tenant_id', '1', true);   -- true = chỉ trong transaction này
```
- Phải `ENABLE ROW LEVEL SECURITY` **và** có policy. Bật RLS mà không có policy → role thường thấy 0 dòng (default deny).
- `USING` lọc dòng được đọc/sửa/xóa. `WITH CHECK` chặn dòng ghi vào không thỏa điều kiện.
- Superuser, role `BYPASSRLS` luôn qua RLS; chủ bảng qua RLS trừ khi `FORCE ROW LEVEL SECURITY`. Vì thế phải **kiểm thử bằng role của ứng dụng** (`SET ROLE`).
- `current_setting('x', true)` không lỗi khi chưa đặt (trả NULL), nên an toàn theo hướng từ chối.
- Đặt tenant bằng `set_config(…, true)` trong transaction, không phải ở mức session: connection pooling (O04) dùng chung connection giữa các client, giá trị mức session sẽ rò sang người khác.
- Chi phí: policy so sánh cột với `current_setting` rẻ và dùng được index; policy có subquery sang bảng khác có thể đắt (ex07).

## 5. SQL injection
```sql
-- SAI: ghép chuỗi
EXECUTE 'SELECT … WHERE email = ''' || p_email || '''';      -- p_email = ' OR '1'='1  → trả mọi khách
-- ĐÚNG: giá trị đi bằng tham số, định danh qua whitelist + %I
EXECUTE format('SELECT … WHERE email = $1 ORDER BY %I', p_order_by) USING p_email;
```
- **Giá trị**: luôn là tham số (`$1`, `USING`, prepared statement của driver). Postgres không bao giờ diễn giải tham số như SQL.
- **Định danh** (tên cột/bảng, `ASC/DESC`): không tham số hóa được. Kiểm tra trong danh sách cho phép rồi dùng `format('%I', …)` hoặc `quote_ident()`. `format('%L')`/`quote_literal()` dành cho giá trị khi bắt buộc phải ghép.
- Xóa dấu nháy (`replace(x, '''', '')`) hay lọc từ khóa không phải là phòng thủ.
- Giảm thiệt hại: dù đã tham số hóa vẫn nên dùng role ít quyền (mục 1): lỗi còn sót thì chỉ lộ những gì role đó đọc được.

## Đo bằng gì
- `\dp`, `\ddp`, `\du` trong psql; `information_schema.role_table_grants`, `information_schema.column_privileges`.
- `has_table_privilege('role', 'bảng', 'SELECT')`, `has_column_privilege`, `has_schema_privilege`.
- `pg_roles` (`rolsuper`, `rolcanlogin`, `rolbypassrls`), `pg_policies` (xem policy RLS).
- `SET ROLE tên_role` (hoặc `SET LOCAL ROLE` trong transaction) rồi chạy thử và `EXPLAIN (ANALYZE, BUFFERS)` để thấy policy trong plan.

## Bẫy hay gặp
1. Thiếu `USAGE` trên schema.
2. `GRANT ALL` cho app "cho nhanh"; app kết nối bằng owner/superuser.
3. Quên `ALTER DEFAULT PRIVILEGES`: bảng mới sau migration không ai đọc được.
4. Tạo policy mà quên `ENABLE ROW LEVEL SECURITY`; test RLS bằng superuser (luôn thấy mọi thứ).
5. `current_setting('app.x')` không có `true` → lỗi khi chưa đặt; đặt tenant ở mức session với pooler.
6. Ghép chuỗi vào SQL; tự chế hàm "escape".
7. `security_invoker = true` trên view khi người gọi không có quyền bảng gốc.

## Postgres-specific
- Role gộp user và group; MySQL tách `user@host`. Quyền theo cột và RLS là tính năng chuẩn có sẵn của Postgres (MySQL không có RLS).
- Role là đối tượng của cả cluster, không thuộc database: `DROP ROLE` phải `DROP OWNED BY` trong từng DB trước.
