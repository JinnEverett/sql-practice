-- db: shop_s
-- ordered
-- Giải thích: toán tử ? (có key ở mức đầu). NOT (properties ? 'device') = thiếu key. count FILTER đếm có điều kiện.
--   Lưu ý: '{"device": null}' vẫn CÓ key (? trả true) dù giá trị null; ở đây dữ liệu thiếu hẳn key.
-- Bẫy: properties->>'device' IS NULL gộp cả "thiếu key" và "key có giá trị null" (ở dữ liệu này hai cách cho cùng số).
SELECT event_type,
       count(*) AS n_events,
       count(*) FILTER (WHERE NOT properties ? 'device') AS n_missing_device,
       round(100.0 * count(*) FILTER (WHERE NOT properties ? 'device') / count(*), 2) AS pct_missing
FROM events
GROUP BY event_type
ORDER BY event_type;
