-- db: lab
-- mode: check
-- reset
-- Giải thích: RLS (Row-Level Security) cho database tự lọc dòng theo policy, bất kể câu lệnh của ứng dụng có nhớ `WHERE tenant_id = …` hay không.
--   ENABLE ROW LEVEL SECURITY bật cơ chế; policy USING quyết định dòng nào NHÌN THẤY (SELECT/UPDATE/DELETE), WITH CHECK quyết định dòng mới/sau khi sửa có HỢP LỆ không (INSERT/UPDATE).
--   Tenant hiện tại lấy từ biến phiên `app.tenant_id` (ứng dụng gọi `SET LOCAL app.tenant_id = '…'` ở đầu mỗi transaction). current_setting(…, true) trả NULL thay vì lỗi khi chưa đặt;
--   nullif(…, '') xử lý trường hợp biến tồn tại nhưng rỗng. So sánh với NULL cho ra NULL → không dòng nào khớp (đóng cửa an toàn, "fail closed").
--   Chủ bảng (owner) và superuser BỎ QUA RLS (trừ khi FORCE ROW LEVEL SECURITY), nên ứng dụng phải kết nối bằng role KHÁC owner.
-- Bẫy: bật RLS mà không có policy → role thường thấy 0 dòng; chỉ có USING mà thiếu WITH CHECK (với FOR ALL thì WITH CHECK mặc định = USING, nhưng policy riêng cho SELECT thì không bảo vệ INSERT);
--   test bằng superuser rồi tưởng RLS không hoạt động (superuser bypass).
ALTER TABLE r09.invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON r09.invoices
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
