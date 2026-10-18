-- sai: chỉ lower(), không bỏ dấu
SELECT lower(properties->>'query') AS normalized_query, count(*) AS n_searches, count(DISTINCT properties->>'query') AS n_variants
FROM events WHERE event_type = 'search' GROUP BY 1 ORDER BY n_searches DESC, normalized_query;
