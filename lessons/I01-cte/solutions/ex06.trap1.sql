WITH moved AS (DELETE FROM i01.orders WHERE status = 'cancelled' AND created_at < '2026-07-01' RETURNING id, user_id, status, created_at, total)
INSERT INTO i01.orders_archive (id, user_id, status, created_at, total) SELECT * FROM moved;
