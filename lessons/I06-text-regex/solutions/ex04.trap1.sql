SELECT lower(trim(properties->>'query')) AS query_norm, count(*) AS n_searches, count(DISTINCT properties->>'query') AS n_variants
FROM events WHERE event_type = 'search' GROUP BY 1 ORDER BY n_searches DESC, query_norm;
