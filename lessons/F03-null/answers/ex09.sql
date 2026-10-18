-- Lần 1: chỉ lọc birth_date is null (405 dòng)
-- Lần 2: + phone is not null (282 dòng)
-- Lần 3: + deleted_at is null (273 dòng)
select id,coalesce(full_name,'Quý khách') as greeting_name, phone from users where birth_date is null and phone is not null and deleted_at is null and country = 'VN' order by id asc;
