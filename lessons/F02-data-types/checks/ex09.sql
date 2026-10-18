-- db: lab
-- ordered
SELECT id, created_local, created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' AS created_at
FROM f02.legacy_orders
WHERE created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' >= '2025-01-01 00:00+00'
  AND created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' <  '2026-01-01 00:00+00'
ORDER BY created_at, id;
