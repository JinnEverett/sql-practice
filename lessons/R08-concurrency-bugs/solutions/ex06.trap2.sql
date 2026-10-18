-- sai: khóa theo thứ tự (from, to) thay vì theo id → hai chiều ngược nhau vẫn khóa ngược thứ tự
CREATE OR REPLACE FUNCTION r08.transfer(p_from int, p_to int, p_amount numeric) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM r08.accounts WHERE id = p_from FOR UPDATE;
  PERFORM pg_sleep(0.5);
  PERFORM 1 FROM r08.accounts WHERE id = p_to FOR UPDATE;
  UPDATE r08.accounts SET balance = balance - p_amount WHERE id = p_from;
  UPDATE r08.accounts SET balance = balance + p_amount WHERE id = p_to;
END $$;
