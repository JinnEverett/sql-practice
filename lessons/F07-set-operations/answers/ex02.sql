select 'order' as kind, count(*) as n_rows
from orders
union all
select 'event' as kind, count(*) as n_rows
from events
where user_id is not null
order by kind asc;
