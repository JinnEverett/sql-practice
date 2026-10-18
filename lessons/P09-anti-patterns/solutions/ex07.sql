-- db: shop_m
-- mode: check
-- Giải thích: N+1: vòng lặp ở ứng dụng chạy 1 query lấy danh sách + 50 query "đơn mới nhất của khách i". Mỗi query không index là một Seq Scan 11 929 page → 50 × 11 929 = ~600 000 buffers.
--   Một câu duy nhất với index (user_id, created_at DESC, id DESC) và LATERAL (mỗi khách một lần dò index, LIMIT 1): 154 buffers. DISTINCT ON cũng được (395 buffers; đọc mọi đơn của 50 khách trong index).
--   Khách "whale" (user 1 có ~10% đơn) khiến LATERAL tốt hơn DISTINCT ON khi số đơn mỗi khách rất lệch.
-- Bẫy: giữ vòng lặp ở app; DISTINCT ON không index (Sort tràn đĩa); LATERAL không index (50 lần Seq Scan).
CREATE INDEX ON orders (user_id, created_at DESC, id DESC);
-- query
SELECT u.id AS user_id, o.id AS order_id, o.created_at
FROM generate_series(1, 50) AS u(id)
CROSS JOIN LATERAL (SELECT id, created_at FROM orders WHERE user_id = u.id ORDER BY created_at DESC, id DESC LIMIT 1) o;
