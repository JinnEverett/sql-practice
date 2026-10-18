-- sai: không dedupe lô → DO NOTHING giữ bản đến trước (e3 v1 thay vì v2)
INSERT INTO r03.events (event_id, payload, received_at)
SELECT event_id, payload, received_at FROM r03.inbox
ON CONFLICT (event_id) DO NOTHING;
