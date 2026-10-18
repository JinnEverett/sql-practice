-- cách đúng khác: khóa dòng bằng SELECT … FOR UPDATE rồi kiểm tra
CREATE FUNCTION r08.reserve(p_product int, p_qty int) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v_stock int;
BEGIN
  SELECT stock INTO v_stock FROM r08.products WHERE id = p_product FOR UPDATE;
  IF v_stock IS NULL OR v_stock < p_qty THEN RETURN false; END IF;
  UPDATE r08.products SET stock = stock - p_qty WHERE id = p_product;
  INSERT INTO r08.orders (product_id, qty) VALUES (p_product, p_qty);
  RETURN true;
END $$;
