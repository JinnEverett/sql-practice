select id, created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' created_at_vn, total_amount
from orders
where total_amount >= 5000000 and created_at >= '2025-11-11+07' and created_at < '2025-11-12+07'
order by created_at asc, id asc;
