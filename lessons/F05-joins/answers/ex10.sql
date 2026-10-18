select o.id as order_id, o.total_amount as total_amount, oi.n_lines as n_lines, coalesce(sum(p.amount)filter (where p.status 
= 'succeeded'),0) as total_paid
from orders o left join (select order_id, count(line_no) as n_lines from order_items group by order_id) oi on o.id = oi.order_id left 
join payments p on p.order_id = o.id and p.status = 'succeeded' where o.id >= 1685 and o.id <= 1694 group by 1,2,3
order by o.id asc;
