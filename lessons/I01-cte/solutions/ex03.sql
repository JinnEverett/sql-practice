-- db: shop_s
-- ordered
-- Giải thích: CTE p giữ đúng tập giao dịch cần xét (một chỗ định nghĩa, khỏi lặp điều kiện); CTE total tính tổng một lần.
-- Bẫy: tính tổng trên mọi payment (kể cả failed/refunded) làm mẫu số; lọc năm theo UTC.
WITH p AS (
  SELECT method, amount
  FROM payments
  WHERE status = 'succeeded'
    AND created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07'
), total AS (
  SELECT sum(amount) AS s FROM p
)
SELECT method,
       count(*) AS n_payments,
       sum(amount) AS amount,
       round(100.0 * sum(amount) / (SELECT s FROM total), 1) AS pct
FROM p
GROUP BY method
ORDER BY amount DESC;
