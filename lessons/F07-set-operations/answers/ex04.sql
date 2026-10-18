select distinct user_id from orders except select distinct user_id from orders o join payments p on o.id = p.order_id and p.status = 'succeeded' group by user_id order by user_id asc;
