-- db: shop_s
-- ordered
SELECT order_id, total_amount, total_paid, total_paid - total_amount AS diff
FROM (SELECT o.id AS order_id, o.total_amount,
             coalesce((SELECT sum(p.amount) FROM payments p
                       WHERE p.order_id = o.id AND p.status = 'succeeded'), 0) AS total_paid
      FROM orders o
      WHERE o.status NOT IN ('cancelled', 'refunded')
        AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07') t
WHERE total_paid <> total_amount
ORDER BY order_id;
