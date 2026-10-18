select line_no, p.name as product_name, c.name as category_name, quantity, quantity*unit_price as line_total
from orders o inner join order_items oi on o.id = oi.order_id inner join products p on oi.product_id = p.id inner join categories c on p.category_id = c.id where o.id = 1
order by line_no asc;
