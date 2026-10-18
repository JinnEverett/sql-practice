CREATE FUNCTION i09.order_lines_stock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE i09.products SET stock = stock - NEW.quantity WHERE id = NEW.product_id AND stock >= NEW.quantity;
    IF NOT FOUND THEN RAISE EXCEPTION 'không đủ tồn kho' USING ERRCODE = 'check_violation'; END IF;
    RETURN NEW;
  END IF;
  RETURN OLD;
END $$;
CREATE TRIGGER trg_order_lines_stock BEFORE INSERT OR DELETE ON i09.order_lines FOR EACH ROW EXECUTE FUNCTION i09.order_lines_stock();
