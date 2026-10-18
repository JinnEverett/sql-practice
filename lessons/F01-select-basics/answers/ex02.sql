select id, full_name, email, created_at
from users
where users.country like 'VN' and extract(year from created_at) = 2025
order by created_at asc, id asc
;
