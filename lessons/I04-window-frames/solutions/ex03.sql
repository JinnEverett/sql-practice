-- db: shop_s
-- ordered
-- Giải thích: trung bình trượt 7 ngày = avg(revenue) OVER (ORDER BY ngay ROWS BETWEEN 6 PRECEDING AND CURRENT ROW).
--   Ngày 01/09 cần doanh thu 26–31/08 → nguồn phải lấy từ 26/08, tính window, RỒI mới lọc chỉ in tháng 9 (lọc ở tầng ngoài).
--   ROWS đếm theo dòng: đúng là "7 ngày" chỉ khi ngày nào cũng có dòng (ở đây mọi ngày đều có đơn).
-- Bẫy: nguồn chỉ lấy tháng 9 → 6 ngày đầu trung bình trên ít hơn 7 ngày; lọc tháng 9 cùng tầng với window.
WITH daily AS (
  SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay, sum(total_amount) AS revenue
  FROM orders
  WHERE created_at >= '2026-08-26 00:00+07' AND created_at < '2026-10-01 00:00+07'
    AND status NOT IN ('cancelled', 'refunded')
  GROUP BY 1
), ma AS (
  SELECT ngay, revenue,
         round(avg(revenue) OVER (ORDER BY ngay ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS ma7
  FROM daily
)
SELECT ngay, revenue, ma7
FROM ma
WHERE ngay >= date '2026-09-01'
ORDER BY ngay;
