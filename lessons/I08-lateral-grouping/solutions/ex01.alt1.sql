SELECT user_id, order_id, created_at, total_amount FROM (
  SELECT user_id, id AS order_id, created_at, total_amount,
         row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn
  FROM orders WHERE user_id <= 5) t
WHERE rn <= 2 ORDER BY user_id, created_at DESC;
