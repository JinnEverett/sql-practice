-- db: lab
-- ordered
SELECT id, user_id, old_phone, new_phone, old_city, new_city FROM f03.profile_changes
WHERE old_phone IS DISTINCT FROM new_phone OR old_city IS DISTINCT FROM new_city
ORDER BY id;
