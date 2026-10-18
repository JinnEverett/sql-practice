-- db: shop_s
-- ordered
SELECT status, count(*) AS n_orders FROM orders GROUP BY status ORDER BY n_orders DESC;
