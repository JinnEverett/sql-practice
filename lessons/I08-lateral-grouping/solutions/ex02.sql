-- db: shop_s
-- ordered
-- Giải thích: GROUP BY ROLLUP (country, status) = GROUPING SETS ((country, status), (country), ()): thêm dòng tổng theo quốc gia
--   và dòng tổng chung. Ở dòng tổng, cột được "cuộn" là NULL; grouping(col) = 1 cho biết NULL đó là dòng tổng chứ không phải dữ liệu NULL.
-- Bẫy: coalesce(status, '(tổng)') sẽ đặt nhãn sai nếu dữ liệu thật có NULL (an toàn hơn là CASE WHEN grouping(status) = 1);
--   sắp xếp làm dòng tổng lẫn giữa các dòng chi tiết.
SELECT CASE WHEN grouping(country) = 1 THEN '(tất cả)' ELSE country END AS country,
       CASE WHEN grouping(status) = 1 THEN '(tổng)' ELSE status END AS status,
       count(*) AS n_orders
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at >= '2026-07-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  AND u.country IN ('JP', 'SG')
GROUP BY ROLLUP (country, status)
ORDER BY grouping(country), country, grouping(status), status;
