select u.id as id, u.full_name as full_name, count(o.id) as n_orders
from users u left join orders o on u.id = o.user_id and o.created_at >= '2026-09-01 +07' and o.created_at < '2026-10-01 +07'
where u.country = 'SG' group by 1,2
order by n_orders desc, id asc;
