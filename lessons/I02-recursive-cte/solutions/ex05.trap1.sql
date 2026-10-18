SELECT b.id, b.full_name, count(*) AS n_direct, count(*) AS n_total
FROM i02.employees e JOIN i02.employees b ON b.id = e.manager_id GROUP BY b.id, b.full_name ORDER BY n_total DESC, b.id;
