SELECT token, count(*) AS n FROM events, regexp_split_to_table(lower(trim(properties->>'query')), '\s+') AS token
WHERE event_type = 'search' GROUP BY token ORDER BY n DESC, token LIMIT 10;
