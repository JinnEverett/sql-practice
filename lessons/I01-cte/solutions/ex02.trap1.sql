WITH monthly AS (SELECT date_trunc('month', created_at) AS m, sum(total_amount) AS revenue FROM orders WHERE status = 'delivered' GROUP BY 1),
best AS (SELECT extract(year FROM m) AS y, max(revenue) AS revenue FROM monthly GROUP BY 1)
SELECT extract(year FROM monthly.m)::int AS nam, extract(month FROM monthly.m)::int AS thang, monthly.revenue
FROM monthly JOIN best ON best.y = extract(year FROM monthly.m) AND best.revenue = monthly.revenue ORDER BY nam;
