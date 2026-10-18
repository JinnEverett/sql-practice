-- db: shop_s
-- ordered
SELECT user_id FROM orders WHERE status = 'delivered'
INTERSECT
SELECT user_id FROM orders WHERE status = 'refunded'
ORDER BY user_id;
