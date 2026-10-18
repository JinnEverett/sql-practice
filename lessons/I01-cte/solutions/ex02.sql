-- db: shop_s
-- ordered
-- Giải thích: CTE monthly tính doanh thu từng tháng (giờ VN); CTE best tìm max mỗi năm TỪ monthly; JOIN lại để lấy tháng đạt max.
--   CTE sau được tham chiếu CTE trước, đọc từ trên xuống như các bước tính.
-- Bẫy: SELECT năm, tháng, max(revenue) GROUP BY năm → lỗi "tháng phải nằm trong GROUP BY"; cắt tháng theo UTC.
WITH monthly AS (
  SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m,
         sum(total_amount) AS revenue
  FROM orders
  WHERE status = 'delivered'
  GROUP BY 1
), best AS (
  SELECT extract(year FROM m) AS y, max(revenue) AS revenue
  FROM monthly
  GROUP BY 1
)
SELECT extract(year FROM monthly.m)::int AS nam,
       extract(month FROM monthly.m)::int AS thang,
       monthly.revenue
FROM monthly
JOIN best ON best.y = extract(year FROM monthly.m) AND best.revenue = monthly.revenue
ORDER BY nam;
