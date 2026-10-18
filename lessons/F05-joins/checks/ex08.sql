-- db: shop_s
-- ordered
SELECT DISTINCT o.id AS order_id, o.created_at, o.total_amount
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p     ON p.id = oi.product_id
WHERE p.brand = 'Samsung' AND o.status = 'delivered'
  AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
ORDER BY o.id;
