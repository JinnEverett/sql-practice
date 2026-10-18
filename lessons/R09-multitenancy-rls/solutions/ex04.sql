-- db: lab
-- mode: check
-- reset
-- Giải thích: view mặc định chạy với quyền của CHỦ view (owner = người tạo, ở đây là postgres, bypass RLS), không phải quyền của người truy vấn. Vì vậy
--   `SELECT * FROM payment_totals` từ role ứng dụng bỏ qua policy của bảng gốc và lộ doanh thu mọi tenant dù bảng gốc đã có RLS.
--   Postgres 15+: `security_invoker = true` bắt view chạy với quyền người gọi → RLS của bảng gốc áp dụng. (Cách cũ/khác: tự thêm WHERE tenant_id = current_setting(...) vào view,
--   hoặc đặt view cho owner là role không bypass RLS.)
-- Bẫy: tin rằng RLS trên bảng gốc tự bảo vệ mọi view/hàm; hàm SECURITY DEFINER cũng bypass RLS theo cách tương tự.
ALTER VIEW r09.payment_totals SET (security_invoker = true);
