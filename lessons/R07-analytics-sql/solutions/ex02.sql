-- db: shop_s
-- ordered
-- expect-rows: 12
-- Giải thích: retention theo cohort = trong số khách của cohort, bao nhiêu % còn mua ở tháng thứ k sau tháng đầu.
--   (1) o: các cặp (khách, tháng có mua) khử trùng; (2) first: cohort của mỗi khách; (3) lưới cohort × offset 0..3 bằng generate_series để ô nào
--   không có ai hoạt động vẫn hiện với 0; (4) LEFT JOIN từ lưới sang first rồi sang o đúng tháng cohort + offset; count(o.user_id) bỏ qua NULL.
--   Tháng offset 0 luôn 100% (mọi người mua ở tháng đầu của họ).
-- Bẫy: INNER JOIN làm mất ô có 0 người hoạt động; tính mẫu số bằng số khách hoạt động trong tháng k thay vì kích thước cohort; đổi tháng theo UTC.
WITH o AS (
  SELECT user_id, date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS m
  FROM orders WHERE status <> 'cancelled' GROUP BY 1, 2
), first AS (
  SELECT user_id, min(m) AS cohort FROM o GROUP BY user_id
), cohorts AS (
  SELECT cohort, count(*) AS size FROM first WHERE cohort BETWEEN '2026-01-01' AND '2026-03-01' GROUP BY cohort
), grid AS (
  SELECT c.cohort, k AS month_offset, c.size FROM cohorts c CROSS JOIN generate_series(0, 3) k
)
SELECT g.cohort AS cohort_month, g.month_offset,
       count(o.user_id) AS active_users,
       round(100.0 * count(o.user_id) / g.size, 1) AS retention_pct
FROM grid g
JOIN first f ON f.cohort = g.cohort
LEFT JOIN o ON o.user_id = f.user_id AND o.m = (g.cohort + make_interval(months => g.month_offset))::date
GROUP BY g.cohort, g.month_offset, g.size
ORDER BY g.cohort, g.month_offset;
