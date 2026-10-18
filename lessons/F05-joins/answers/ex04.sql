select u.id, u.full_name, count(o.id) as n_orders 
from users u left join orders o on o.user_id = u.id where country = 'JP'
group by u.id, u.full_name
order by n_orders desc, id asc;
