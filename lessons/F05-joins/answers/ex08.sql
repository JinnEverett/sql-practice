select o.id as order_id, o.created_at as created_at, o.total_amount as total_amount
from orders o join order_items oi on oi.order_id = o.id join products p on oi.product_id = p.id where brand = 'Samsung' and o.created_at >= '2026-09-01 +07' and o.created_at < '2026-10-01 +07' and o.status = 'delivered'
group by 1,2,3
order by order_id asc;
