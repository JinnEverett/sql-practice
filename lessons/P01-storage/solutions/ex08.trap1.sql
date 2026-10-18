SELECT 'events' AS table_name, count(*) AS n_rows, pg_total_relation_size('events') / 8192 AS heap_pages, round(pg_total_relation_size('events')::numeric / count(*)) AS bytes_per_row FROM events
UNION ALL SELECT 'order_items', count(*), pg_total_relation_size('order_items') / 8192, round(pg_total_relation_size('order_items')::numeric / count(*)) FROM order_items
UNION ALL SELECT 'orders', count(*), pg_total_relation_size('orders') / 8192, round(pg_total_relation_size('orders')::numeric / count(*)) FROM orders
UNION ALL SELECT 'payments', count(*), pg_total_relation_size('payments') / 8192, round(pg_total_relation_size('payments')::numeric / count(*)) FROM payments
ORDER BY table_name;
