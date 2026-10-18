select id, created_at, created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' as created_at_vn
from orders
where id >= 1 and id <= 5
order by id asc;
