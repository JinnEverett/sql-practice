select o.id as order_id, o.total_amount as total_amount, coalesce((select sum(amount) from payments where status = 'succeeded' and order_id = o.id),0) as total_paid, coalesce((select sum(amount) from payments where status = 'succeeded'
 and order_id = o.id),0) -o.total_amount as diff from orders o
where o.status NOT IN ('cancelled', 'refunded') and created_at >= '2026-09-01 +07' and created_at < '2026-10-01 +07' and coalesce((select sum(amount) from payments where status = 'succeeded' and order_id = o.id),0) -o.total_amount <> 0
order by order_id asc;
