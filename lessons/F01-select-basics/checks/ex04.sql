-- db: shop_s
-- ordered
SELECT id, user_id, status, total_amount FROM orders
WHERE status IN ('cancelled', 'refunded') AND total_amount >= 5000000
ORDER BY total_amount DESC, id;
