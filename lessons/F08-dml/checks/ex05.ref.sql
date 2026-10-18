DELETE FROM f08.cart_items c USING f08.products p WHERE p.id = c.product_id AND (NOT p.is_active OR p.stock = 0);
