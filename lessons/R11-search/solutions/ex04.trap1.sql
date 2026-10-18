-- sai: ILIKE không chịu được lỗi gõ
SELECT id, name, 0::numeric AS sim FROM products WHERE name ILIKE '%op lung samsug%' ORDER BY id LIMIT 5;
