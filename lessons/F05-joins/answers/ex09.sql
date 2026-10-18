select u1.id as user_id_1, u2.id as user_id_2, btrim(lower(u1.email)) as email
from users u1 join users u2 on u1.id < u2.id and btrim(lower(u1.email)) = btrim(lower(u2.email))
order by u1.id asc;
