BEGIN;
SELECT $q$SELECT count(*) AS n_events, round(avg(value), 2) AS avg_value FROM r12.events_p WHERE ts >= '2026-03-01 00:00+07' AND ts < '2026-04-01 00:00+07'$q$ AS ref \gset
SELECT pg_temp.plan(:'ans', false) AS p \gset
SELECT pg_temp.ck(pg_temp.same(:'ans', :'ref'), 'kết quả đúng (tháng 3 theo giờ VN)');
SELECT coalesce(jsonb_agg(DISTINCT v), '[]') AS scanned FROM jsonb_path_query(:'p'::jsonb, '$.** ? (@."Relation Name" like_regex "^events_p_2026_")."Relation Name"') v \gset
SELECT pg_temp.ck(jsonb_array_length(:'scanned'::jsonb) BETWEEN 1 AND 2, 'plan chỉ quét 1–2 partition (quét ' || jsonb_array_length(:'scanned'::jsonb) || ': ' || :'scanned' || ')');
SELECT pg_temp.ck(:'scanned'::jsonb <@ '["events_p_2026_02", "events_p_2026_03"]'::jsonb, 'chỉ gồm partition tháng 2 (7 giờ cuối theo UTC) và tháng 3');
ROLLBACK;
