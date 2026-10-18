select id, name, price,round(price/25000,2) as price_usd
from products where round(price/25000,2) > 20 and is_active = true and category_id in (9,10)
order by price_usd desc, id asc
;
