-- db: shop_s
-- ordered
SELECT u.id, u.full_name, count(o.id) AS n_orders
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
                  AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
WHERE u.country = 'SG'
GROUP BY u.id, u.full_name
ORDER BY n_orders DESC, u.id;
