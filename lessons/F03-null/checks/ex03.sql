-- db: lab
-- ordered
SELECT id, name, brand FROM f03.products_import
WHERE brand IS DISTINCT FROM 'Sony' ORDER BY id;
