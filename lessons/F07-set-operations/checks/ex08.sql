-- db: shop_s
SELECT count(*) AS n_tong, count(user_id) AS n_co_tai_khoan
FROM (SELECT user_id FROM events UNION SELECT user_id FROM orders) t;
