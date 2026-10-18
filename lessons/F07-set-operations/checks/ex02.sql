-- db: shop_s
-- ordered
SELECT kind, count(*) AS n_rows
FROM (
  SELECT user_id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS d, 'order' AS kind FROM orders
  UNION ALL
  SELECT user_id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date,      'event'         FROM events
  WHERE user_id IS NOT NULL
) t
GROUP BY kind
ORDER BY kind;
