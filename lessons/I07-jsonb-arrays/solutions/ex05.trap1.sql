SELECT properties->>'utm_source' AS utm_source, count(*) AS n_events, count(DISTINCT user_id) AS n_visitors
FROM events WHERE event_type = 'page_view' AND properties ? 'utm_source' GROUP BY 1 ORDER BY n_events DESC;
