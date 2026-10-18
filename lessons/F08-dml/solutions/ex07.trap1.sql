INSERT INTO f08.daily_stats (day, orders, revenue)
SELECT created_at::date, count(*), sum(total) FROM f08.new_orders GROUP BY 1
ON CONFLICT (day) DO UPDATE SET orders = f08.daily_stats.orders + EXCLUDED.orders, revenue = f08.daily_stats.revenue + EXCLUDED.revenue;
