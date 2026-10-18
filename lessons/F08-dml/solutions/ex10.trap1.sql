UPDATE f08.orders SET status = 'cancelled', cancelled_at = now()
WHERE status = 'pending' AND created_at <= '2026-10-10 00:00:00+07' RETURNING id, user_id;
