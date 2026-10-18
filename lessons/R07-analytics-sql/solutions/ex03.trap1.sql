-- sai: mỗi bước đếm distinct visitor có loại event đó, không xét thứ tự thời gian
WITH ev AS (SELECT coalesce(user_id::text, anonymous_id) AS visitor, event_type, created_at FROM events
            WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07')
SELECT step, visitors, round(100.0 * visitors / first_value(visitors) OVER (ORDER BY ord), 1) AS pct_of_step1
FROM (SELECT CASE event_type WHEN 'product_view' THEN 1 WHEN 'add_to_cart' THEN 2 ELSE 3 END AS ord, event_type AS step, count(DISTINCT visitor) AS visitors
      FROM ev WHERE event_type IN ('product_view', 'add_to_cart', 'checkout') GROUP BY 1, 2) t
ORDER BY ord;
