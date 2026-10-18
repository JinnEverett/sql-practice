select 'mua hàng' as nhom, count(user_id) as n_khach from (select distinct u.id as user_id from users u where exists (select 1 from orders o where o.user_id = u.id) and u.deleted_at is null)
union all
select 'chỉ xem' as nhom, count(user_id) from (select distinct u.id as user_id from users u where exists (select 1 from events e where e.user_id = u.id) and not exists (select 1 from orders o where o.user_id = u.id) and u.deleted_at is null)
union all
select 'ngủ đông' as nhom, count(user_id) from (select distinct u.id as user_id from users u where not exists (select 1 from events e where e.user_id = u.id) and not exists (select 1 from orders o where o.user_id = u.id) and u.deleted_at is null) order by nhom asc;
