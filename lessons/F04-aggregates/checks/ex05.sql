-- db: shop_s
-- ordered
SELECT event_type, count(*) AS n_events, count(user_id) AS n_logged_in_events, count(DISTINCT user_id) AS n_users
FROM events GROUP BY event_type ORDER BY event_type;
