-- db: shop_s
-- ordered
SELECT s.user_id, u.full_name, s.total_spent
FROM (SELECT user_id, sum(total_amount) AS total_spent
      FROM orders WHERE status = 'delivered' GROUP BY user_id) s
JOIN users u ON u.id = s.user_id
WHERE s.total_spent > 10 * (SELECT avg(t) FROM (SELECT sum(total_amount) AS t
                                                FROM orders WHERE status = 'delivered'
                                                GROUP BY user_id) x)
ORDER BY s.total_spent DESC, s.user_id;
