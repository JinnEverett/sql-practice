select order_id, total, n, round(total*1.0/n) as per_installment, total - round(total*1.0/n)*(n-1) as last_installment
from f02.installment_plans
order by order_id asc;
