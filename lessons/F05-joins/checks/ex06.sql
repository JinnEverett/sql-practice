-- db: shop_s
-- ordered
SELECT p.brand, sum(oi.quantity) AS units, sum(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p     ON p.id = oi.product_id
WHERE o.status = 'delivered'
  AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
GROUP BY p.brand
ORDER BY revenue DESC, p.brand
LIMIT 5;
