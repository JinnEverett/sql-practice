select id, user_id, old_phone, new_phone, old_city, new_city from f03.profile_changes where old_phone IS DISTINCT FROM new_phone or old_city IS DISTINCT FROM new_city order by id asc;
