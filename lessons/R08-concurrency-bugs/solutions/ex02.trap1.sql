-- sai: kiểm tra rồi mới trừ (check-then-act) → request đến sau thấy stock cũ, UPDATE bị chặn rồi phạm CHECK (stock >= 0)
CREATE FUNCTION r08.reserve(p_product int, p_qty int) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v_stock int;
BEGIN
  SELECT stock INTO v_stock FROM r08.products WHERE id = p_product;
  IF v_stock IS NULL OR v_stock < p_qty THEN RETURN false; END IF;
  UPDATE r08.products SET stock = stock - p_qty WHERE id = p_product;
  INSERT INTO r08.orders (product_id, qty) VALUES (p_product, p_qty);
  RETURN true;
END $$;
