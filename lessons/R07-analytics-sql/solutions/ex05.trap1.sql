-- sai: >= 30 phút → khoảng lặng đúng 30 phút của visitor a bị cắt thành phiên mới
WITH f AS (SELECT visitor, at, CASE WHEN at - lag(at) OVER (PARTITION BY visitor ORDER BY at) >= interval '30 minutes' OR lag(at) OVER (PARTITION BY visitor ORDER BY at) IS NULL THEN 1 ELSE 0 END AS is_new FROM r07.hits),
s AS (SELECT visitor, at, sum(is_new) OVER (PARTITION BY visitor ORDER BY at) AS session_no FROM f)
SELECT visitor, session_no::int AS session_no, min(at) AS started_at, max(at) AS ended_at, count(*) AS n_events, max(at) - min(at) AS duration
FROM s GROUP BY visitor, session_no ORDER BY visitor, session_no;
