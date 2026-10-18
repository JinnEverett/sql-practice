-- db: shop_s
-- ordered
SELECT country, count(*) AS n_users, count(city) AS n_with_city, count(deleted_at) AS n_deleted
FROM users GROUP BY country ORDER BY n_users DESC, country;
