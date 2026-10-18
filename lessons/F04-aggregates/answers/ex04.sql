select method, count(*) as n_payments, count(*) filter(where status = 'succeeded') as n_succeeded, round(100.0 * count(*) filter
(where status = 'succeeded') / nullif(count(*),0),2) as success_rate from payments group by method order by success_rate desc, method asc
;
