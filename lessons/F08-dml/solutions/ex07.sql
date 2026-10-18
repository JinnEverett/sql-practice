-- db: lab
-- mode: state
-- Giải thích: Gom new_orders theo NGÀY GIỜ VN ((created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) rồi ON CONFLICT (day) DO UPDATE cộng dồn: bảng.cột + EXCLUDED.cột.
-- Bẫy: created_at::date cắt theo UTC (TimeZone của session) → đơn 00:30 ngày 16 giờ VN rơi vào ngày 15. Và không GROUP BY trước thì 2 đơn cùng ngày trong một lệnh → lỗi 'ON CONFLICT DO UPDATE command cannot affect row a second time'.
INSERT INTO f08.daily_stats (day, orders, revenue)
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, count(*), sum(total) FROM f08.new_orders GROUP BY 1
ON CONFLICT (day) DO UPDATE SET orders = f08.daily_stats.orders + EXCLUDED.orders, revenue = f08.daily_stats.revenue + EXCLUDED.revenue;
