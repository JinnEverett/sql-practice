-- db: shop_s
-- mode: manual
-- Demo: plan của running total trên toàn bảng (không ANALYZE).
EXPLAIN (COSTS OFF) SELECT max(cum) FROM (SELECT sum(total_amount) OVER (ORDER BY created_at, id) AS cum FROM orders) t;
EXPLAIN (COSTS OFF) SELECT max(cum) FROM (SELECT sum(total_amount) OVER (ORDER BY created_at, id ROWS UNBOUNDED PRECEDING) AS cum FROM orders) t;
