-- db: lab
-- mode: check
-- reset
-- Giải thích: view chạy với quyền của CHỦ view (mặc định, security_invoker = off): role support chỉ cần SELECT trên view, không cần quyền gì
--   trên bảng gốc. Đây là cách phơi một phần dữ liệu (cột/dòng) ra ngoài. Nếu đặt security_invoker = true thì view dùng quyền của NGƯỜI GỌI
--   và role support sẽ bị từ chối trên bảng gốc (đúng khi bạn muốn RLS của bảng gốc áp lên người gọi, sai ở ca này).
-- Bẫy: cấp SELECT trên bảng customers cho support (lộ password_hash); WITH (security_invoker = true) → support không đọc được view.
CREATE ROLE o01_support NOLOGIN;
CREATE VIEW o01.v_customers_public AS
SELECT id, name, tenant_id FROM o01.customers;
GRANT USAGE ON SCHEMA o01 TO o01_support;
GRANT SELECT ON o01.v_customers_public TO o01_support;
