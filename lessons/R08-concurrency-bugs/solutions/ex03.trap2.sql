-- sai: kiểm tra đúng nhưng quên tăng version → người thứ hai (cùng version) cũng lưu được
CREATE FUNCTION r08.update_price(p_id int, p_expected_version int, p_new_price numeric) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.products SET price = p_new_price WHERE id = p_id AND version = p_expected_version;
  RETURN FOUND;
END $$;
