with a as (select avg(total_amount) as avg from orders)
select id as order_id, total_amount, round(a.avg,2) as avg_all, round(total_amount - a.avg,2) as diff 
from orders cross join a where id >= 5001 and id <= 5010
order by order_id asc;
