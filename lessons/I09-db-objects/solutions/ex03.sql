-- db: lab
-- mode: check
-- reset
-- Giải thích: view đơn giản (một bảng, không DISTINCT/GROUP BY/window) là updatable: INSERT/UPDATE/DELETE qua view được chuyển thành
--   thao tác trên bảng gốc. WITH CHECK OPTION chặn thao tác làm dòng "trượt ra ngoài" view (điều kiện status = 'active').
--   Không có nó, INSERT qua view chèn được khách blocked vào bảng mà view không còn nhìn thấy.
-- Bẫy: quên WITH CHECK OPTION; liệt kê cột thiếu status (INSERT qua view không đặt được status); dùng LOCAL/CASCADED không khác khi chỉ có 1 tầng view.
CREATE VIEW i09.v_active_customers AS
SELECT id, name, email, status
FROM i09.customers
WHERE status = 'active'
WITH CHECK OPTION;
