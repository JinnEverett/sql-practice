select id as order_id, created_at, total_amount from orders o where status = 'delivered' and  exists (select 1 from payments 
where order_id = o.id and status = 'failed' ) and created_at >= '2026-09-01 +07' and created_at < '2026-10-01 +07' order by order_id asc;
