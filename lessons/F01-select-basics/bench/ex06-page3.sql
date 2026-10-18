-- ex06 bonus: trang 3 của toàn bộ đơn
select id, created_at, status, total_amount
from orders
order by created_at desc, id desc
limit 5 offset 10;
