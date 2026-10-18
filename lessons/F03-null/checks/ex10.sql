-- db: shop_s
SELECT count(*) AS orders_count, sum(total_amount) AS revenue FROM orders
WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
  AND total_amount >= 10000000 AND discount_code IS DISTINCT FROM 'VIP15';
