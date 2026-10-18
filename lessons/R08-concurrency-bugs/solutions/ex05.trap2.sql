-- sai: chỉ khóa dòng của chính mình → không chặn được người kia sửa dòng khác
CREATE FUNCTION r08.go_off_call(p_doc int) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM r08.doctors WHERE id = p_doc FOR UPDATE;
  IF (SELECT count(*) FROM r08.doctors WHERE on_call) <= 1 THEN RETURN false; END IF;
  UPDATE r08.doctors SET on_call = false WHERE id = p_doc AND on_call;
  RETURN FOUND;
END $$;
