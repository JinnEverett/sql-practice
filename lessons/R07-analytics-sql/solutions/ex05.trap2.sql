-- sai: bỏ PARTITION BY visitor → lag chạy xuyên visitor, phiên đầu của b dính vào cuối phiên của a
WITH f AS (SELECT visitor, at, CASE WHEN at - lag(at) OVER (ORDER BY visitor, at) > interval '30 minutes' OR lag(at) OVER (ORDER BY visitor, at) IS NULL THEN 1 ELSE 0 END AS is_new FROM r07.hits),
s AS (SELECT visitor, at, sum(is_new) OVER (PARTITION BY visitor ORDER BY at) AS session_no FROM f)
SELECT visitor, session_no::int AS session_no, min(at) AS started_at, max(at) AS ended_at, count(*) AS n_events, max(at) - min(at) AS duration
FROM s GROUP BY visitor, session_no ORDER BY visitor, session_no;
