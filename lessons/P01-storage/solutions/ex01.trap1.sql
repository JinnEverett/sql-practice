SELECT pg_total_relation_size('orders') / 8192 AS n_pages, count(*) AS n_rows,
       round(count(*)::numeric / (pg_total_relation_size('orders') / 8192), 1) AS rows_per_page,
       round(pg_total_relation_size('orders')::numeric / count(*)) AS bytes_per_row
FROM orders;
