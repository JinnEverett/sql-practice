-- db: shop_m
-- mode: check
-- Giải thích: trang "đơn của một khách" theo cursor. Index (user_id, created_at DESC, id DESC) có đủ: cột lọc đứng đầu, rồi đúng thứ tự sắp xếp.
--   Plan là Index Scan dừng sau 20 dòng, KHÔNG có Sort, đọc khoảng 20 buffer. Chỉ có index (created_at DESC, id DESC) thì planner bỏ qua nó và Seq Scan
--   cả 1M đơn (~12 000 buffer) vì khách này chỉ có ~250 đơn rải khắp bảng. Không index: cũng Seq Scan + top-N sort.
-- Bẫy: index đúng cột nhưng sai thứ tự (user_id, id) hoặc thiếu DESC → vẫn cần Sort hoặc scan ngược chưa chắc dùng được cho hướng hỗn hợp.
CREATE INDEX orders_user_created_idx ON orders (user_id, created_at DESC, id DESC);
-- query
SELECT id, created_at, total_amount
FROM orders
WHERE user_id = 200 AND (created_at, id) < ('2026-01-01 00:00+00', 900000)
ORDER BY created_at DESC, id DESC
LIMIT 20;
