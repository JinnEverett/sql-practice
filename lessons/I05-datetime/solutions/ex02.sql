-- db: shop_s
-- ordered
-- Giải thích: generate_series(0, 23) đảm bảo đủ 24 khung giờ; giờ lấy theo GIỜ VN. Tỉ lệ dùng window sum(…) OVER () trên số đã gom.
-- Bẫy: extract(hour FROM created_at) theo UTC → giờ cao điểm lệch 7 tiếng (đỉnh rơi vào 13h–14h UTC thay vì 20h–21h VN).
WITH h AS (
  SELECT extract(hour FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int AS gio, count(*) AS n
  FROM orders
  WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07'
  GROUP BY 1
)
SELECT g AS gio, coalesce(h.n, 0) AS n_orders,
       round(100.0 * coalesce(h.n, 0) / sum(coalesce(h.n, 0)) OVER (), 1) AS pct
FROM generate_series(0, 23) AS g
LEFT JOIN h ON h.gio = g
ORDER BY gio;
