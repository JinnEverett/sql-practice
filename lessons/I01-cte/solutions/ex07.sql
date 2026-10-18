-- db: lab
-- mode: state
-- Giải thích: CTE items giữ danh sách dòng hàng (VALUES); CTE o chèn đơn với total = tổng từ items và RETURNING id;
--   câu INSERT ngoài cùng dùng id vừa sinh để chèn dòng hàng. Một câu lệnh, không cần ứng dụng đọc id rồi gửi câu thứ hai.
-- Bẫy: tự điền id = 11 (lệch sequence, sai khi có người chèn song song); tính total bằng tay.
WITH items (line_no, product_id, quantity, unit_price) AS (
  VALUES (1, 101, 2, 100000.00), (2, 205, 1, 250000.00), (3, 330, 3, 15000.00)
), o AS (
  INSERT INTO i01.orders (user_id, status, created_at, total)
  SELECT 7, 'pending', '2026-10-17 10:00+07', sum(quantity * unit_price) FROM items
  RETURNING id
)
INSERT INTO i01.order_items (order_id, line_no, product_id, quantity, unit_price)
SELECT o.id, i.line_no, i.product_id, i.quantity, i.unit_price
FROM o CROSS JOIN items i;
