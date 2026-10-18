-- sai: đếm rồi cập nhật không khóa gì → cả hai session cùng thấy 2 người trực và cùng nghỉ
CREATE FUNCTION r08.go_off_call(p_doc int) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT count(*) FROM r08.doctors WHERE on_call) <= 1 THEN RETURN false; END IF;
  UPDATE r08.doctors SET on_call = false WHERE id = p_doc AND on_call;
  RETURN FOUND;
END $$;
