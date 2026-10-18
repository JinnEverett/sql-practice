-- db: shop_s
-- ordered
-- Giải thích: gom doanh thu theo ngày trước, rồi sum(revenue) OVER (ORDER BY ngay) cộng dồn. Có ORDER BY mà không ghi frame thì
--   frame mặc định là RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW = từ đầu tới dòng hiện tại → đúng nghĩa lũy kế.
--   Window lồng aggregate: sum(sum(total_amount)) OVER (…) cũng được, ở đây tách CTE cho dễ đọc.
-- Bẫy: cộng dồn trên từng ĐƠN rồi mới gom ngày; quên ORDER BY trong OVER (ra tổng cả tháng ở mọi dòng).
WITH daily AS (
  SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay, sum(total_amount) AS revenue
  FROM orders
  WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
    AND status NOT IN ('cancelled', 'refunded')
  GROUP BY 1
)
SELECT ngay, revenue, sum(revenue) OVER (ORDER BY ngay) AS cum_revenue
FROM daily
ORDER BY ngay;
