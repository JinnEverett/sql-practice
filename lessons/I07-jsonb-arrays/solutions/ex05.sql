-- db: shop_s
-- ordered
-- Giải thích: khách vãng lai không có user_id nhưng có anonymous_id → định danh "người xem" = coalesce(user_id::text, anonymous_id).
--   Lọc page_view có key utm_source; đếm event và đếm người (DISTINCT).
-- Bẫy: count(DISTINCT user_id) bỏ qua mọi khách vãng lai (NULL); quên ép user_id::text (coalesce cần cùng kiểu).
SELECT properties->>'utm_source' AS utm_source,
       count(*) AS n_events,
       count(DISTINCT coalesce(user_id::text, anonymous_id)) AS n_visitors
FROM events
WHERE event_type = 'page_view' AND properties ? 'utm_source'
GROUP BY 1
ORDER BY n_events DESC;
