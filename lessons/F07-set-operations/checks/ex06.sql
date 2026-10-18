-- db: shop_s
-- ordered
WITH w AS (
  SELECT oi.product_id, o.created_at
  FROM order_items oi JOIN orders o ON o.id = oi.order_id
  WHERE o.status <> 'cancelled'),
t1 AS (SELECT product_id FROM w
       WHERE created_at >= '2026-09-01 00:00:00+07' AND created_at < '2026-09-08 00:00:00+07'),
t2 AS (SELECT product_id FROM w
       WHERE created_at >= '2026-09-08 00:00:00+07' AND created_at < '2026-09-15 00:00:00+07')
SELECT product_id, 'chỉ tuần 1' AS nhom FROM (SELECT product_id FROM t1 EXCEPT SELECT product_id FROM t2) a
UNION ALL
SELECT product_id, 'chỉ tuần 2' FROM (SELECT product_id FROM t2 EXCEPT SELECT product_id FROM t1) b
ORDER BY product_id;
