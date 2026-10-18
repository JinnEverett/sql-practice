-- db: shop_s
-- ordered
SELECT id, full_name FROM users
WHERE id IN (SELECT user_id FROM orders
             WHERE id IN (SELECT order_id FROM order_items
                          WHERE product_id IN (SELECT id FROM products WHERE brand = 'Apple')))
ORDER BY id;
