select o.id as order_id, full_name, status, total_amount
from orders o inner join users u on o.user_id = u.id
where o.id >= 5001 and o.id <= 5010
order by o.id asc;
