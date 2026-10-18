delete from f08.cart_items c where exists (select 1 from f08.products p where p.id = c.product_id and (p.is_active = false or p.stock = 0));
