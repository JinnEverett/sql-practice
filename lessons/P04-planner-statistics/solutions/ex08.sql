-- db: shop_m
-- mode: manual
-- Demo: ngưỡng autovacuum ANALYZE của orders và mức sai của n_distinct (ở shop_m; chạy `ANALYZE VERBOSE orders;` để xem số page đã quét).
SELECT reltuples::bigint AS rows, 50 + 0.1 * reltuples AS autoanalyze_threshold FROM pg_class WHERE relname = 'orders';
SELECT s.attname, s.n_distinct AS estimated FROM pg_stats s WHERE s.tablename = 'orders' AND s.attname IN ('user_id', 'total_amount');
