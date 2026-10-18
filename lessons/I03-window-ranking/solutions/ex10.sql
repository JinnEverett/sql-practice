-- db: shop_s
-- mode: manual
-- Demo: plan của hai cách lấy đơn mới nhất mỗi khách (không ANALYZE).
EXPLAIN (COSTS OFF) SELECT count(*) FROM (SELECT user_id, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn FROM orders) t WHERE rn = 1;
EXPLAIN (COSTS OFF) SELECT count(*) FROM (SELECT DISTINCT ON (user_id) user_id FROM orders ORDER BY user_id, created_at DESC, id DESC) t;
