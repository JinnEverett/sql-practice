-- cách đúng khác: khóa tư vấn (advisory lock) theo giao dịch cho cả hàng rào "ít nhất 1 người trực"
CREATE FUNCTION r08.go_off_call(p_doc int) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('r08.on_call'));
  IF (SELECT count(*) FROM r08.doctors WHERE on_call) <= 1 THEN RETURN false; END IF;
  UPDATE r08.doctors SET on_call = false WHERE id = p_doc AND on_call;
  RETURN FOUND;
END $$;
