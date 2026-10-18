# R09 · Multi-tenancy & Row-Level Security

Đọc khoảng 10 phút. Mọi bài chạy trên DB `lab`, schema `r09` (tạo bởi `setup.sql`, kèm hai role không đăng nhập được `r09_app` và `r09_support` để `SET ROLE`; role nằm ở mức cluster, muốn dọn: `DROP OWNED BY r09_app, r09_support; DROP ROLE r09_app, r09_support;` sau khi bỏ schema).

## Mục tiêu: sau buổi này bạn làm được
- So sánh ba mô hình multi-tenant: **bảng dùng chung + `tenant_id`**, **schema-per-tenant**, **database-per-tenant**.
- Thiết kế bảng dùng chung sao cho dữ liệu chéo tenant bị chặn ngay ở tầng ràng buộc (FK ghép).
- Cài **Row-Level Security** đúng: `USING`, `WITH CHECK`, đóng cửa an toàn khi thiếu tenant, view và hàm không bypass.
- Provision schema cho tenant mới mà không bị SQL injection.
- Đo chi phí RLS và nhận ra chỗ nó gây chậm.

---

## 1. Ba mô hình
| | Bảng dùng chung + `tenant_id` | Schema-per-tenant | Database-per-tenant |
|---|---|---|---|
| Cô lập | logic (ràng buộc + RLS) | schema + quyền | mạnh nhất (kết nối, backup riêng) |
| Số tenant thực tế | hàng triệu | vài trăm – vài nghìn | vài chục – vài trăm |
| Migration | 1 lần | N lần (script lặp qua schema) | N lần, N cluster/DB |
| Backup/restore 1 tenant | khó (lọc theo tenant_id) | `pg_dump -n` | `pg_dump` cả DB |
| Hàng xóm ồn ào | dễ xảy ra (chung bảng, chung index) | một phần (chung server) | cách ly tốt |
| Chi phí catalog | nhỏ | N × số bảng object (phình `pg_class`) | N catalog |
Mặc định cho SaaS nhiều tenant nhỏ: bảng dùng chung + RLS. Tenant lớn hoặc có yêu cầu pháp lý riêng: tách schema/database (hybrid: tenant lớn tách riêng, còn lại dùng chung). D08 sẽ đi sâu thiết kế.

## 2. Bảng dùng chung: ràng buộc chéo tenant
Mọi bảng có `tenant_id NOT NULL`. FK đơn `invoices.customer_id → customers(id)` **không** đảm bảo hai bên cùng tenant. Dùng FK ghép `(customer_id, tenant_id) → customers(id, tenant_id)` (ex01). Mọi index nên có `tenant_id` đứng đầu hoặc đủ chọn lọc theo cách khác (ex07). PK ghép `(tenant_id, id)` cũng là lựa chọn phổ biến (chia sẻ locality trong cùng tenant).

## 3. Row-Level Security
```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
  USING      (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int)   -- dòng nào NHÌN THẤY
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);  -- dòng nào được GHI
-- ứng dụng, đầu mỗi transaction:
SELECT set_config('app.tenant_id', '42', true);   -- = SET LOCAL
```
- `USING` áp dụng cho dòng đã có (SELECT/UPDATE/DELETE); `WITH CHECK` áp dụng cho dòng mới hoặc dòng sau khi sửa (INSERT/UPDATE). Vi phạm `WITH CHECK` báo `42501`; vi phạm `USING` thì dòng **âm thầm không thấy** (UPDATE/DELETE tác động 0 dòng).
- **Owner của bảng và superuser bypass RLS** (trừ khi `ALTER TABLE … FORCE ROW LEVEL SECURITY`; superuser và role `BYPASSRLS` luôn bypass). Ứng dụng phải kết nối bằng role khác owner. Test bằng `SET ROLE` (ex02), không bằng superuser.
- **Đóng cửa an toàn (fail closed):** biến phiên chưa đặt → `current_setting(…, true)` trả NULL; chuỗi rỗng → `nullif(…, '')`. So sánh với NULL không khớp dòng nào → 0 dòng. Policy `current_setting('app.tenant_id')::int` thì ném lỗi khi biến chưa tồn tại (ex03).
- **Policy PERMISSIVE** (mặc định) được OR với nhau; **RESTRICTIVE** được AND. Thêm quyền đọc cho nhóm khác = thêm policy `TO <role>` (ex05); thiếu `TO` thì policy áp dụng cho mọi role.
- **View bypass RLS** vì chạy với quyền owner của view; dùng `WITH (security_invoker = true)` (Postgres 15+) hoặc tự lọc trong view (ex04). Hàm `SECURITY DEFINER` cũng bypass.
- Có `pgbouncer` ở chế độ transaction: dùng `set_config(…, true)` (cục bộ theo transaction), không dùng `SET` ở mức phiên (rò sang client khác dùng chung connection). Xem O04.
- RLS **không** thay được index, và không phải thuốc tiên cho hiệu năng (ex07). Nó cũng không che giấu mọi kênh phụ (lỗi trùng khóa UNIQUE có thể tiết lộ tồn tại của dòng tenant khác).

## 4. Schema-per-tenant
```sql
CREATE SCHEMA t_acme;
CREATE TABLE t_acme.invoices (LIKE r09.tpl_invoices INCLUDING ALL);
SET search_path = t_acme;       -- ứng dụng chọn tenant bằng search_path
```
Dùng `format('%I', …)` và kiểm tra định dạng slug khi ghép tên vào lệnh động, nếu không là lỗ hổng SQL injection (ex06). Migration phải lặp qua N schema; số bảng/index tăng N lần làm catalog và `pg_dump` chậm; prepared statement và cache plan theo `search_path` cần lưu ý.

## Bẫy hay gặp
1. Test RLS bằng superuser/owner rồi kết luận RLS "không hoạt động".
2. Quên `WITH CHECK` (hoặc policy ghi) → tenant này ghi dòng mang tenant_id của tenant khác.
3. Policy ném lỗi khi thiếu `app.tenant_id` (thay vì 0 dòng).
4. View/hàm `SECURITY DEFINER` mở lỗ hổng bỏ qua RLS.
5. Policy gọi hàm VOLATILE (plpgsql mặc định): chậm 19× và mất index (ex07).
6. Quên `tenant_id` đứng đầu trong index; FK đơn không chặn tham chiếu chéo tenant.
7. `SET app.tenant_id` mức phiên qua connection pool dùng chung.

## Postgres-specific
- RLS có từ Postgres 9.5; `security_invoker` cho view từ 15. `FORCE ROW LEVEL SECURITY` buộc cả owner chịu policy. `pg_policies` liệt kê policy (`SELECT * FROM pg_policies WHERE schemaname = 'r09'`).
- `LIKE … INCLUDING ALL` sao chép cột, default, identity, CHECK, index và PK từ bảng khuôn (không sao chép FK).
