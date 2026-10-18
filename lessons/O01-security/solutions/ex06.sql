-- db: lab
-- mode: check
-- reset
-- Giải thích: Row Level Security thêm điều kiện vào MỌI truy vấn trên bảng, do engine áp dụng. Phải (1) ENABLE ROW LEVEL SECURITY và (2) tạo POLICY;
--   có policy mà chưa ENABLE thì không có tác dụng. Khi bật RLS mà không có policy nào, role thường thấy 0 dòng (default deny).
--   Superuser và chủ bảng KHÔNG chịu RLS (trừ khi FORCE ROW LEVEL SECURITY cho chủ bảng; superuser và role BYPASSRLS thì luôn qua).
--   USING lọc dòng được thấy/sửa/xóa; WITH CHECK chặn dòng mới/sửa không thỏa điều kiện (policy FOR ALL mà thiếu WITH CHECK thì USING cũng dùng làm WITH CHECK).
--   current_setting('app.tenant_id', true): tham số true = "missing_ok", chưa đặt thì trả NULL, nên tenant_id = NULL → không dòng nào, an toàn theo hướng từ chối.
--   Ứng dụng đặt tenant bằng `SELECT set_config('app.tenant_id', '1', true)` (true = chỉ trong transaction hiện tại, an toàn với connection pooling: O04).
-- Bẫy: tạo policy nhưng quên ENABLE ROW LEVEL SECURITY; current_setting không có missing_ok (lỗi khi chưa đặt); đặt tenant ở mức session với pooler dùng chung connection.
ALTER TABLE o01.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON o01.orders
  FOR ALL TO o01_tenant_app
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
