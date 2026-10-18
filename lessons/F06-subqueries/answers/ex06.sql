select id, name, category_id, price, round((select avg(price) from products pc where pc.is_active = true and pc.category_id = p.category_id)) as category_avg
from products p
where is_active = true and price > (select avg(price) from products pc where pc.is_active = true and pc.category_id = p.category_id)
order by p.category_id asc, p.price desc, id asc;
