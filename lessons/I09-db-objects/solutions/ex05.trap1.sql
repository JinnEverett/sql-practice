CREATE FUNCTION i09.apply_discount(p_order_id int, p_pct numeric)
RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE v_total numeric(12,2);
BEGIN
  IF p_pct < 0 OR p_pct > 50 THEN RAISE EXCEPTION 'discount % không hợp lệ', p_pct USING ERRCODE = 'invalid_parameter_value'; END IF;
  UPDATE i09.orders SET total = round(total * (1 - p_pct / 100), 2) WHERE id = p_order_id AND status IN ('pending', 'paid') RETURNING total INTO v_total;
  RETURN v_total;
END $$;
