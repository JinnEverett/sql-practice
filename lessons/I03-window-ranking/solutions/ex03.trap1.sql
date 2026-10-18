SELECT quartile, count(*) AS n_users, min(total_spent) AS min_spent, max(total_spent) AS max_spent
FROM (SELECT user_id, sum(total_amount) AS total_spent, ntile(4) OVER (ORDER BY sum(total_amount), user_id) AS quartile
      FROM orders WHERE status = 'delivered' GROUP BY user_id) t
GROUP BY quartile ORDER BY quartile;
