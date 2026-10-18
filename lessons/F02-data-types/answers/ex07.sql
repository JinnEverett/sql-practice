select id, is_paid, total_vnd
from f02.legacy_orders
where is_paid::boolean  = true
order by id asc;
