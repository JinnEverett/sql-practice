-- sai: ghi đè event đã lưu (e2 bị đổi thành v9)
INSERT INTO r03.events (event_id, payload, received_at)
SELECT DISTINCT ON (event_id) event_id, payload, received_at FROM r03.inbox ORDER BY event_id, received_at DESC
ON CONFLICT (event_id) DO UPDATE SET payload = EXCLUDED.payload, received_at = EXCLUDED.received_at;
