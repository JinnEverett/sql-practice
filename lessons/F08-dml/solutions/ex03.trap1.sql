UPDATE f08.products SET price = round(price * 1.10, 0), updated_at = now() WHERE price < 500000;
