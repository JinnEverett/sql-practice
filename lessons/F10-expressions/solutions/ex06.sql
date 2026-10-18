-- db: shop_s
-- ordered
-- Giải thích: lọc bằng literal có múi giờ (+07), nửa mở [2026-01-01, 2027-01-01). Cắt tháng theo GIỜ VN:
--   date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'). to_char(…, 'MM/YYYY') để hiển thị,
--   nhưng GROUP BY / ORDER BY theo giá trị thời gian (đừng sắp theo chuỗi khi có nhiều năm).
--   Định dạng tiền: to_char với dấu ',' cố định rồi thay bằng '.', vì 'G' phụ thuộc lc_numeric của server (đang là en_US → ',').
-- Bẫy: date_trunc('month', created_at) cắt theo UTC (TimeZone của session) → đơn 0h–7h ngày 1 giờ VN rơi về tháng trước.
SELECT to_char(date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'MM/YYYY') AS thang,
       count(*) AS n_orders,
       replace(to_char(sum(total_amount), 'FM999,999,999,999'), ',', '.') || ' ₫' AS doanh_thu
FROM orders
WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07'
  AND status NOT IN ('cancelled', 'refunded')
GROUP BY date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
ORDER BY date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh');
