select u.id as user_id, full_name, sum(o.total_amount) as total_spent
from users u join orders o on o.user_id = u.id
where o.status = 'delivered' group by u.id, full_name having sum(o.total_amount) > 10 * (select avg(st.sum_cus) from (select sum(total_amount) as sum_cus from orders where status = 'delivered' group by user_id) st) 
order by total_spent desc, u.id asc;
