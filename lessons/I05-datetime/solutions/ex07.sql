-- db: shop_s
-- ordered
-- Giải thích: mỗi đơn lấy thời điểm thanh toán THÀNH CÔNG ĐẦU TIÊN (min, vì có đơn bị trừ tiền 2 lần) và phương thức của nó.
--   So khoảng chờ với interval '15 minutes'. Đơn không có thanh toán thành công vẫn tính vào n_orders (LEFT JOIN) nhưng không đạt SLA.
-- Bẫy: JOIN mọi payment → đơn trừ tiền 2 lần bị đếm 2 lần; INNER JOIN làm mất đơn chưa thanh toán khỏi mẫu số.
WITH first_pay AS (
  SELECT DISTINCT ON (order_id) order_id, method, created_at AS paid_at
  FROM payments
  WHERE status = 'succeeded'
  ORDER BY order_id, created_at, id
)
SELECT coalesce(f.method, '(chưa thanh toán)') AS method,
       count(*) AS n_orders,
       count(*) FILTER (WHERE f.paid_at - o.created_at <= interval '15 minutes') AS n_within_15m,
       round(100.0 * count(*) FILTER (WHERE f.paid_at - o.created_at <= interval '15 minutes') / count(*), 1) AS pct
FROM orders o
LEFT JOIN first_pay f ON f.order_id = o.id
WHERE o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
GROUP BY 1
ORDER BY 1;
