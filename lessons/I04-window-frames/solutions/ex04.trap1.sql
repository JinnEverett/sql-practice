SELECT id, created_at, total_amount, first_value(id) OVER w AS first_order_id, last_value(id) OVER w AS last_order_id,
       max(total_amount) OVER w AS max_total
FROM orders WHERE user_id = 1 AND created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
WINDOW w AS (ORDER BY created_at, id) ORDER BY created_at, id;
