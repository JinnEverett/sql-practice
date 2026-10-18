-- sai: không khử trùng theo ngày → user 3 có hai dòng cùng ngày làm hỏng phép trừ row_number
WITH d AS (SELECT user_id, (login_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day FROM r07.logins),
g AS (SELECT user_id, day, day - (row_number() OVER (PARTITION BY user_id ORDER BY day))::int AS island FROM d)
SELECT user_id, min(day) AS streak_start, max(day) AS streak_end, count(*) AS days FROM g GROUP BY user_id, island ORDER BY user_id, streak_start;
