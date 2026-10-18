select id, user_id, status, total_amount
from orders
where total_amount >= 5000000 and status in ('cancelled', 'refunded')
order by total_amount desc, id asc;
