select id, name,(select count(*) from products where products.category_id = c.id and products.is_active = true) as  n_active_products
from categories c
where not exists (select 1 from categories cp where c.id = cp.parent_id) 
order by n_active_products desc, id asc;
