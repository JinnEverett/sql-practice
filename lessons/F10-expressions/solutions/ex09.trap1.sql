SELECT segment, count(*) AS n_users, round(avg(monetary)) AS avg_monetary
FROM (SELECT CASE WHEN frequency >= 5 THEN 'Trung thành'
                  WHEN monetary >= 50000000 AND recency_days <= 90 THEN 'VIP'
                  WHEN recency_days > 180 THEN 'Ngủ đông' ELSE 'Thường' END AS segment, monetary
      FROM (SELECT o.user_id, date '2026-10-01' - max((o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) AS recency_days,
                   count(*) AS frequency, sum(o.total_amount) AS monetary
            FROM orders o JOIN users u ON u.id = o.user_id
            WHERE o.status = 'delivered' AND u.deleted_at IS NULL GROUP BY o.user_id) c) s
GROUP BY segment ORDER BY array_position(ARRAY['VIP', 'Trung thành', 'Ngủ đông', 'Thường'], segment);
