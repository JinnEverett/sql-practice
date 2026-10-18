select id, full_name, email, created_at from users
where deleted_at is null and country = 'VN'
order by created_at asc, id asc
limit 10;
