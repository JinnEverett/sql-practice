-- db: shop_s
-- ordered
SELECT id, created_at, status, total_amount FROM orders
WHERE user_id = 1 ORDER BY created_at DESC, id DESC LIMIT 5 OFFSET 10;
