-- sai: đánh số trên MỌI payment rồi mới lọc succeeded → bản failed hoặc refunded chiếm rn = 1 và bản succeeded đầu tiên bị coi là trùng
SELECT order_id, id AS payment_id, amount, extract(epoch FROM created_at - first_created)::int AS seconds_after_first
FROM (
  SELECT p.*, row_number() OVER w AS rn, first_value(created_at) OVER w AS first_created
  FROM payments p
  WINDOW w AS (PARTITION BY order_id ORDER BY created_at, id)
) t
WHERE rn > 1 AND status = 'succeeded'
ORDER BY order_id, payment_id;
