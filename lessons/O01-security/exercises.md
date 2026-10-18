# O01 · Bài tập (Security)

Mọi bài chạy trên DB **`lab`**, schema `o01` (script chấm tự chạy `setup.sql`: dựng bảng, xóa các role của bài nếu có, và dựng sẵn role `o01_tenant_app` cho ex06).
Mỗi bài là một nhóm lệnh DDL/DCL vào `answers/exNN.sql`, **tự đủ** (tự `CREATE ROLE` nếu đề yêu cầu role). Bộ chấm chạy lệnh của bạn rồi **đóng vai** từng role (`SET LOCAL ROLE`) để thử quyền thật, trong `BEGIN … ROLLBACK`, nên không để lại role nào.
Tự chấm: `bash tools/check.sh lessons/O01-security 01`. Để thử tay, chạy trong `psql` với `\i` rồi `SET ROLE …; …; RESET ROLE;` (nhớ chạy lại `setup.sql` để reset).
Bảng: `o01.customers(id, tenant_id, name, email, password_hash)` (6 khách; tenant 1: id 1–3, tenant 2: id 4–6) · `o01.orders(id, tenant_id, customer_id, status, total)` (10 đơn; đơn 1–6 tenant 1, đơn 7–10 tenant 2).
Mật khẩu role đăng nhập ở môi trường thật đặt bằng `\password`, không ghi vào script.

**Pass:** 6/7 (6 bài chấm tự động) + ex07 câu hỏi quy mô tự đối chiếu.

---

## 🟢 Cơ bản

### ex01 · Role chỉ đọc
Tạo role `o01_ro` **không đăng nhập được** (role nhóm quyền) có quyền **đọc** (chỉ `SELECT`) mọi bảng hiện có trong schema `o01`. Không cấp gì cho `PUBLIC`.
- Kỳ vọng: dưới `o01_ro` đọc được `orders` (10 đơn) và `customers`; `INSERT/UPDATE/DELETE/CREATE TABLE` đều bị từ chối `42501`.

### ex02 · Bảng mới sau migration
Team báo: *"Sau deploy hôm qua, báo cáo lỗi `permission denied for table shipments`. Bảng `shipments` mới tạo từ migration."* Cấu hình role `o01_ro` như ex01 **và** đảm bảo bảng tạo sau trong `o01` cũng tự đọc được (vẫn chỉ đọc).
- Kỳ vọng: sau khi bộ chấm tạo `o01.shipments`, `o01_ro` đọc được nó mà không cần GRANT lại, nhưng không `INSERT` được.

---

## 🟡 Kết hợp

### ex03 · Role cho ứng dụng (least privilege)
Tạo role `o01_app` **được đăng nhập**, không phải superuser/createdb/createrole. Quyền: 
- `customers`: chỉ đọc `id, tenant_id, name, email` (**không** `password_hash`).
- `orders`: `SELECT`, `INSERT`, và `UPDATE` chỉ cột `status`.
- Không `DELETE`, không `TRUNCATE`, không ghi `customers`.
- Kỳ vọng: `SELECT password_hash` và `SELECT *` trên `customers` đều bị `42501`; đổi `status` được; đổi `total` bị `42501`.

### ex04 · Nhóm hỗ trợ xem khách, không thấy mật khẩu
Nhóm CSKH cần tra `id, name, tenant_id` của khách. Tạo role `o01_support` (không đăng nhập), view `o01.v_customers_public(id, name, tenant_id)` và cấp cho `o01_support` đúng quyền đọc view, **không** cấp gì trên bảng `customers`.
- Kỳ vọng: `o01_support` đọc được view (6 dòng); đọc `customers`/`orders` hay ghi qua view đều bị `42501`.

---

## 🔴 Thực tế

### ex05 · "Tìm khách bằng email ra cả danh sách"
Team an ninh báo: *"Ô tìm kiếm khách dùng hàm `o01.find_customer_bad` (xem `setup.sql`). Nhập `' OR '1'='1` ra toàn bộ khách."* Viết `o01.find_customer(p_email text, p_order_by text DEFAULT 'id') RETURNS TABLE (id int, name text)` bằng SQL động nhưng an toàn:
- `p_email` là **giá trị**: không bao giờ được diễn giải như SQL.
- `p_order_by` chọn cột sắp xếp, chỉ cho phép `id`, `name`, `email`; giá trị khác → lỗi `invalid_parameter_value` (`22023`).
- Kỳ vọng: `find_customer('binh@x.vn')` trả `Bình`; payload `' OR '1'='1` và payload có `DROP TABLE` trả 0 dòng; `p_order_by = 'id; DROP TABLE o01.orders'` hay `'password_hash'` bị `22023`.

### ex06 · "Khách tenant 2 thấy đơn tenant 1"
Team báo: *"Ứng dụng multi-tenant lọc `tenant_id` bằng code, hôm qua một endpoint quên lọc nên lộ đơn giữa hai tenant."* Hãy ép ở database: role ứng dụng `o01_tenant_app` (đã có `SELECT, INSERT` trên `orders`) chỉ thấy và chỉ tạo được đơn của tenant hiện tại, lấy từ tham số phiên `app.tenant_id` (ứng dụng đặt bằng `set_config('app.tenant_id', '1', true)` đầu mỗi transaction). Chưa đặt tham số thì thấy **0 đơn**, không được lỗi.
- Kỳ vọng: tenant 1 thấy 6 đơn, tạo được đơn tenant 1, tạo đơn tenant 2 bị `42501`; tenant 2 thấy 4 đơn (6 + 4 = 10); chưa đặt thấy 0; superuser vẫn thấy tất cả.

---

## 📏 ex07 · Câu hỏi quy mô: chi phí của RLS ở 1M đơn
Trên `shop_m` (1M đơn), role ứng dụng có RLS với ba kiểu policy:
```sql
-- (a) USING (user_id = nullif(current_setting('app.user_id', true), '')::bigint)
-- (b) USING (EXISTS (SELECT 1 FROM users u WHERE u.id = orders.user_id AND u.id = nullif(current_setting('app.user_id', true), '')::bigint))
-- (c) USING (EXISTS (SELECT 1 FROM users u WHERE u.id = orders.user_id AND u.country = 'VN'))
```
Truy vấn của ứng dụng: `SELECT * FROM orders WHERE status = 'paid'`.
1. **Dự đoán** (ghi vào `answers/ex07.md`): plan và thời gian mỗi kiểu ở `m`. Có cần index nào không? Ở `l` thì sao?
2. Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` **dưới role ứng dụng** (`SET LOCAL ROLE`, trong `BEGIN … ROLLBACK`, index và role tạo tạm).
3. Giải thích: vì sao đo bằng superuser cho kết quả sai?

Lời giải và số đo thật: `solutions/ex07.md`.
