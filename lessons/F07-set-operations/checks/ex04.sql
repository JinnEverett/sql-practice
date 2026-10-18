-- db: shop_s
-- ordered
SELECT user_id FROM orders
EXCEPT
SELECT o.user_id FROM orders o JOIN payments p ON p.order_id = o.id WHERE p.status = 'succeeded'
ORDER BY user_id;
