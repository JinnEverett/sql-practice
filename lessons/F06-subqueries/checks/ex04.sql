-- db: shop_s
-- ordered
SELECT o.id AS order_id, o.created_at, o.total_amount FROM orders o
WHERE o.status = 'delivered'
  AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  AND EXISTS (SELECT 1 FROM payments p WHERE p.order_id = o.id AND p.status = 'failed')
ORDER BY o.id;
