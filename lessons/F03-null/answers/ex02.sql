-- Lần 1: nullif(city,'') → sót trường hợp toàn khoảng trắng (id 11, 22)
select id, name, COALESCE(nullif(btrim(city),''),'Chưa cập nhật') as city_display from f03.contacts order by id asc;
