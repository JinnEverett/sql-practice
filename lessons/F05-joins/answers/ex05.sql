select c.id, c.name, coalesce(cp.name,'(gốc)') as parent_name
from categories c left join categories cp on c.parent_id = cp.id
order by c.id asc;
