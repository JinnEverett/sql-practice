select brand, sum(oi.quantity) as units, sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi on oi.order_id = o. id join products p on p.id = oi.product_id 
where o.status = 'delivered' and o.created_at >= '2026-09-01 +07' and o.created_at < '2026-10-01 +07'
group by p.brand               
order by revenue desc limit 5;
