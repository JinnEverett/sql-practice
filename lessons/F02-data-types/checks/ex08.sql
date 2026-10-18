-- db: shop_s
-- ordered
SELECT id, created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS created_at_vn, total_amount
FROM orders
WHERE created_at >= '2025-11-11 00:00+07' AND created_at < '2025-11-12 00:00+07'
  AND total_amount >= 5000000
ORDER BY created_at, id;
