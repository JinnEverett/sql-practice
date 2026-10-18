SELECT event_id, payload->>'v' AS v, received_at FROM r03.events ORDER BY event_id;
