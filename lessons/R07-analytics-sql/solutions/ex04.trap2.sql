-- sai: ngày theo UTC (lần đăng nhập 23:30 UTC ngày 03/03 phải là 04/03 ở VN)
WITH d AS (SELECT DISTINCT user_id, login_at::date AS day FROM r07.logins),
g AS (SELECT user_id, day, day - (row_number() OVER (PARTITION BY user_id ORDER BY day))::int AS island FROM d)
SELECT user_id, min(day) AS streak_start, max(day) AS streak_end, count(*) AS days FROM g GROUP BY user_id, island ORDER BY user_id, streak_start;
