-- db: shop_m
-- mode: manual
-- Demo: plan (không ANALYZE) của query ở shop_m; đổi `-d` sang shop_xs / shop_s để so.
EXPLAIN (COSTS ON) SELECT u.country, count(*) AS n, sum(o.total_amount) AS revenue FROM orders o JOIN users u ON u.id = o.user_id WHERE o.status = 'delivered' GROUP BY u.country ORDER BY revenue DESC;
