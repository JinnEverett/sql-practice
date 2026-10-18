select id, created_local, created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' as created_at
from f02.legacy_orders where created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' >= '2025-01-01 00:00:00+00' and created_local AT TIME ZONE 'Asia/Ho_Chi_Minh' < '2026-01-01 00:00:00+00'
order by created_at asc, id asc;
