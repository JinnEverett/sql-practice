select id, stock, (stock/12) as full_boxes,stock - (stock/12)*12 as remainder, ceil(stock*1.0/12) as boxes_needed
from products
where id >=1 and id <=10
order by id asc;
