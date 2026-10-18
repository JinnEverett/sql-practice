SELECT id, 'P' || substr(sku, 5)::int AS code, upper(brand) || ' · ' || name AS title,
       length(name) - length(trim(name)) AS n_extra_spaces
FROM products WHERE id <= 10 OR name <> trim(name) ORDER BY id;
