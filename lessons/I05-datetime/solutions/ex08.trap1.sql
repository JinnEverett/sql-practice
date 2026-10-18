WITH f AS (
  SELECT u.id, date_trunc('month', u.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m,
         extract(epoch FROM min(o.created_at) - u.created_at) / 86400 AS days_to_first
  FROM users u LEFT JOIN orders o ON o.user_id = u.id
  WHERE u.created_at >= '2025-01-01 00:00+07' AND u.created_at < '2026-01-01 00:00+07' GROUP BY u.id, u.created_at)
SELECT to_char(m, 'YYYY-MM') AS thang_dk, count(*) FILTER (WHERE days_to_first IS NOT NULL) AS n_users,
       count(*) FILTER (WHERE days_to_first IS NULL) AS n_never, round(avg(days_to_first), 1) AS avg_days
FROM f GROUP BY m ORDER BY m;
