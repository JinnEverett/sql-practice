-- db: shop_s
-- ordered
SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS month,
       count(*) AS n_orders, sum(total_amount) AS revenue
FROM orders
WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
  AND status NOT IN ('cancelled', 'refunded')
GROUP BY 1 ORDER BY 1;
