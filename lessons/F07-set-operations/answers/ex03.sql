select user_id from orders where status = 'delivered'
intersect 
select user_id from orders where status = 'refunded'
order by user_id asc;
