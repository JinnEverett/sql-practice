-- db: shop_s
-- ordered
(SELECT user_id FROM events WHERE event_type = 'add_to_cart' AND user_id IS NOT NULL
 INTERSECT
 SELECT user_id FROM events WHERE event_type = 'checkout' AND user_id IS NOT NULL)
EXCEPT
SELECT user_id FROM orders
ORDER BY user_id;
