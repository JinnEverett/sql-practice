-- db: shop_s
-- ordered
SELECT status FROM orders
UNION
SELECT status FROM payments
ORDER BY status;
