-- db: shop_s
-- ordered
SELECT user_id, count(*) AS n_orders, sum(total_amount) AS total_spent
FROM orders
WHERE status = 'delivered' AND created_at >= '2025-01-01 00:00+07' AND created_at < '2026-01-01 00:00+07'
GROUP BY user_id HAVING count(*) >= 20 AND sum(total_amount) >= 150000000
ORDER BY total_spent DESC;
