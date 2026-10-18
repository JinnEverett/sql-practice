-- Mẫu S00: 5 thành phố có nhiều đơn nhất từ đầu năm 2026
SELECT u.city, count(*) AS orders
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at >= timestamptz '2026-01-01 00:00:00+07'
GROUP BY u.city
ORDER BY orders DESC
LIMIT 5;
