select u.id, u.full_name, u.created_at from users u left join orders o on o.user_id = u.id where o.id is null order by id asc;
