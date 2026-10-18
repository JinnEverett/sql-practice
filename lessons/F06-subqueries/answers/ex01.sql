select id, name, price
from products
where price > (select avg(price) from products where is_active = true) and is_active = true
order by price desc, id asc;
