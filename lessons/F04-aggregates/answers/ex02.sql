select country, count(*) as n_users, count(city) as n_with_city, count(deleted_at) as n_deleted from users group by country order by n_users desc, country asc;
