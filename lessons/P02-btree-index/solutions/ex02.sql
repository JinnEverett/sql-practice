-- db: shop_m
-- mode: check
-- Giải thích: với (user_id) plan vẫn phải Sort top-N 28 dòng (34 buffers). Với (user_id, created_at) các dòng của user_id=4242 đã nằm theo created_at,
--   planner đọc ngược (Index Scan Backward) và dừng sau 5 dòng nhờ LIMIT: 8 buffers, không Sort.
-- Bẫy: index (created_at, user_id) (sai thứ tự cột); (user_id) đơn thuần.
CREATE INDEX ON orders (user_id, created_at);
