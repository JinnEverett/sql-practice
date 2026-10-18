select status, count(status) as n_orders from orders group by status order by count(status) desc;
