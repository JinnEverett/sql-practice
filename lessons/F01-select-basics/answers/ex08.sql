select id, name, price
from products
where name ilike '%sony%' and is_active = true and price < 5000000
order by price asc, id asc
;
