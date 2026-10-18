-- db: shop_s
-- ordered
SELECT u.id, u.full_name, u.email FROM users u
WHERE u.deleted_at IS NULL
  AND EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.status = 'delivered'
              AND o.created_at >= '2026-08-01 00:00+07' AND o.created_at < '2026-09-01 00:00+07')
  AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.status <> 'cancelled'
                  AND o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07')
ORDER BY u.id;
