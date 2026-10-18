CREATE FUNCTION i09.log_price_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO i09.price_history (product_id, old_price, new_price) VALUES (OLD.id, OLD.price, NEW.price);
  RETURN NULL;
END $$;
CREATE TRIGGER trg_products_price_history AFTER UPDATE OF price ON i09.products
FOR EACH ROW EXECUTE FUNCTION i09.log_price_change();
