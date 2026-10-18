-- sai: ghi đè mù, không kiểm tra version
CREATE FUNCTION r08.update_price(p_id int, p_expected_version int, p_new_price numeric) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.products SET price = p_new_price, version = version + 1 WHERE id = p_id;
  RETURN FOUND;
END $$;
