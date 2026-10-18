select id, full_name, created_at from users u where not exists (select 1 from events e where e.user_id = u.id) order by u.id 
asc;
