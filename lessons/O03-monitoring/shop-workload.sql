-- O03 ex06 · tải giả lập trên shop_m (1M đơn). Chạy:
--   docker exec -i sql-practice-pg psql -U postgres -d shop_m -X -q < lessons/O03-monitoring/shop-workload.sql
-- Mất khoảng nửa phút. Sau đó tự tìm "top 5 query tệ nhất" trong pg_stat_statements.
SELECT pg_stat_statements_reset();
SELECT format('SELECT count(*) FROM orders WHERE user_id = %s', 1000 + i * 37) FROM generate_series(1, 20) i \gexec
SELECT 'SELECT date_trunc(''month'', created_at), sum(total_amount) FROM orders GROUP BY 1' FROM generate_series(1, 5) \gexec
SELECT format('SELECT * FROM orders WHERE id = %s', 100 + i * 13) FROM generate_series(1, 2000) i \gexec
SELECT 'SELECT count(*) FROM events WHERE properties->>''utm_source'' = ''tiktok''' FROM generate_series(1, 3) \gexec
SELECT 'SELECT u.country, count(*) FROM orders o JOIN users u ON u.id = o.user_id GROUP BY 1' FROM generate_series(1, 10) \gexec
SELECT 'SELECT id FROM products WHERE lower(name) LIKE ''a%''' FROM generate_series(1, 50) \gexec
