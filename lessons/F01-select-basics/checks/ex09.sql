-- db: shop_s
-- ordered
SELECT id, user_id, total_amount, created_at FROM orders
WHERE status = 'pending' AND total_amount >= 2000000
  AND created_at >= '2026-09-01' AND created_at < '2026-10-01'
ORDER BY total_amount DESC, created_at;
