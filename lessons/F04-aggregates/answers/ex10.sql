select order_id, count(*) as n_succeeded, sum(amount) as total_paid from payments where status = 'succeeded' group by 1 having count(*) >=2 order by order_id asc;
