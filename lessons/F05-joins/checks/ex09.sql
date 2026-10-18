-- db: shop_s
-- ordered
SELECT a.id AS user_id_1, b.id AS user_id_2, lower(trim(a.email)) AS email
FROM users a JOIN users b ON lower(trim(a.email)) = lower(trim(b.email)) AND a.id < b.id
ORDER BY a.id, b.id;
