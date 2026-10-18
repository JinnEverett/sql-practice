WITH spent AS (
  SELECT u.city AS city_norm, u.id AS user_id, u.full_name, sum(o.total_amount) AS total_spent
  FROM users u JOIN orders o ON o.user_id = u.id AND o.status = 'delivered'
  WHERE u.country = 'VN' AND u.city IS NOT NULL GROUP BY 1, u.id, u.full_name),
ranked AS (SELECT *, row_number() OVER (PARTITION BY city_norm ORDER BY total_spent DESC, user_id) AS rnk FROM spent)
SELECT city_norm, user_id, full_name, total_spent, rnk FROM ranked WHERE rnk <= 3 ORDER BY city_norm, rnk;
