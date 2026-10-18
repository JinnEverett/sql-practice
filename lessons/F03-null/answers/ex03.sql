select id, name, brand from f03.products_import where brand IS DISTINCT FROM 'Sony' order by id asc;
