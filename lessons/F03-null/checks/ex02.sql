-- db: lab
-- ordered
SELECT id, name, coalesce(nullif(trim(city), ''), 'Chưa cập nhật') AS city_display
FROM f03.contacts ORDER BY id;
