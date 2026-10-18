UPDATE f08.products SET price = round(price * 1.10, 0), updated_at = now() WHERE is_active AND price < 500000;
