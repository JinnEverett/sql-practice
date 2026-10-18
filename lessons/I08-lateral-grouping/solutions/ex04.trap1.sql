SELECT coalesce(properties->>'device', '(tất cả)') AS device, coalesce(event_type, '(tất cả)') AS event_type,
       grouping(properties->>'device', event_type) AS lvl, count(*) AS n_events
FROM events WHERE event_type IN ('add_to_cart', 'checkout')
GROUP BY CUBE (properties->>'device', event_type) ORDER BY lvl, device, event_type;
