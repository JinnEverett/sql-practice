-- sai: không tạo index nào → Seq Scan
SELECT 1;
-- query
SELECT id, created_at, total_amount
FROM orders
WHERE user_id = 200 AND (created_at, id) < ('2026-01-01 00:00+00', 900000)
ORDER BY created_at DESC, id DESC
LIMIT 20;
