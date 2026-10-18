-- query
SELECT count(*) FROM (SELECT id FROM events WHERE event_type = 'search' LIMIT 1001) AS capped;
