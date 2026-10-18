-- db: shop_s
-- ordered
SELECT id, created_at, created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS created_at_vn
FROM orders WHERE id <= 5 ORDER BY id;
