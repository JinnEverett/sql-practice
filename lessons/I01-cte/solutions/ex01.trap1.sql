WITH user_totals AS (SELECT user_id, sum(total_amount) AS total_spent FROM orders WHERE status = 'delivered' GROUP BY user_id)
SELECT user_id, total_spent FROM user_totals
WHERE total_spent > 3 * (SELECT avg(total_amount) FROM orders WHERE status = 'delivered')
ORDER BY total_spent DESC, user_id;
