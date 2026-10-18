-- query
SELECT id, created_at, total_amount FROM orders
WHERE (created_at, id) < ('2025-02-21 05:57:20.456226+00', 100001)
ORDER BY created_at DESC, id DESC LIMIT 20;
