WITH tz (country, zone) AS (
  VALUES ('SG', '+08'), ('KR', '+09'), ('AU', '+10'), ('TH', '+07'), ('JP', '+09'), ('US', '-08'))
SELECT u.country, count(*) AS n_orders,
       count(*) FILTER (WHERE extract(hour FROM o.created_at AT TIME ZONE tz.zone) < 6) AS n_night_local,
       count(*) FILTER (WHERE extract(hour FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') < 6) AS n_night_vn
FROM orders o JOIN users u ON u.id = o.user_id JOIN tz ON tz.country = u.country GROUP BY u.country ORDER BY u.country;
