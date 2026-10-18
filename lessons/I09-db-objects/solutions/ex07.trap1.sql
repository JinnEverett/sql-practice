CREATE FUNCTION i09.order_lines_stock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE i09.products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
    RETURN NEW;
  ELSE
    UPDATE i09.products SET stock = stock + OLD.quantity WHERE id = OLD.product_id;
    RETURN OLD;
  END IF;
END $$;
CREATE TRIGGER trg_order_lines_stock BEFORE INSERT OR DELETE ON i09.order_lines FOR EACH ROW EXECUTE FUNCTION i09.order_lines_stock();
