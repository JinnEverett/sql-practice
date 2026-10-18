-- db: shop_s
-- ordered
-- Giải thích: extract(isodow …) cho Thứ 2 = 1 … Chủ nhật = 7 (dow thì Chủ nhật = 0). Lấy thứ theo GIỜ VN.
--   CASE đơn giản (CASE x WHEN 1 THEN …) đổi số thành nhãn. GROUP BY cả số và nhãn, ORDER BY số.
-- Bẫy: extract(dow) đưa Chủ nhật lên đầu; tính thứ theo UTC (đơn 0h–7h sáng giờ VN bị lùi một ngày).
SELECT CASE extract(isodow FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
         WHEN 1 THEN 'Thứ 2' WHEN 2 THEN 'Thứ 3' WHEN 3 THEN 'Thứ 4' WHEN 4 THEN 'Thứ 5'
         WHEN 5 THEN 'Thứ 6' WHEN 6 THEN 'Thứ 7' WHEN 7 THEN 'Chủ nhật'
       END AS thu,
       count(*) AS n_orders,
       round(100.0 * count(*) / (SELECT count(*) FROM orders
                                 WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07'), 1) AS pct
FROM orders
WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
GROUP BY extract(isodow FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
ORDER BY extract(isodow FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh');
