-- db: shop_s
-- mode: manual
-- Demo: xem plan của hai cách viết (không ANALYZE nên chạy tức thì).
EXPLAIN (COSTS OFF) WITH o AS MATERIALIZED (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
EXPLAIN (COSTS OFF) WITH o AS (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
