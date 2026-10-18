-- sai: check-then-act → request đồng thời thứ hai gặp lỗi 23505 khi ghi key
CREATE FUNCTION r03.charge(p_key text, p_order bigint, p_amount numeric) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE v_id bigint;
BEGIN
  SELECT payment_id INTO v_id FROM r03.idem_keys WHERE key = p_key;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;
  INSERT INTO r03.pay2 (order_id, amount) VALUES (p_order, p_amount) RETURNING id INTO v_id;
  INSERT INTO r03.idem_keys (key, payment_id) VALUES (p_key, v_id);
  RETURN v_id;
END $$;
