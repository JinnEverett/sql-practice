select u.id as id, u.full_name as full_name, u.email as email
from users u join orders o on u.id = o.user_id
where o.created_at >= '2026-08-01 +07' and o.created_at < '2026-09-01 +07' and o.status = 'delivered'  and not exists (select 1 from orders so where so.user_id = u.id and created_at >= '2026-09-01 +07' and created_at < '2026-10-01 +07' and status <> 'cancelled') and u.deleted_at is null group by u.id, u.full_name, u.email
order by u.id asc;
