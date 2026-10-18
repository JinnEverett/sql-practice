-- ordered
SELECT id, status, (cancelled_at IS NOT NULL) AS has_cancelled_at FROM f08.orders ORDER BY id;
