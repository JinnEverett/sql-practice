-- db: shop_m
-- mode: manual
-- Demo: level và dung lượng của PK, rồi số buffers cho một lần tra cứu (cần pageinspect; superuser).
CREATE EXTENSION IF NOT EXISTS pageinspect;
SELECT (bt_metap('orders_pkey')).level AS level, pg_relation_size('orders_pkey') / 8192 AS index_pages;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT id, user_id FROM orders WHERE id = 77;
