update f08.products p set price = round(p.price *1.1), updated_at = now() where p.is_active = true and p.price < 500000;
