select category_id, count(*) as n_active, min(price) as min_price, max(price) as max_price from products where is_active = true 
group by category_id Having count(*) >= 8 order by category_id asc;
