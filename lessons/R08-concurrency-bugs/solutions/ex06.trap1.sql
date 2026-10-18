-- sai: không đổi gì (hàm gốc) → hai chiều ngược nhau gây deadlock 40P01
CREATE OR REPLACE FUNCTION r08.transfer(p_from int, p_to int, p_amount numeric) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.accounts SET balance = balance - p_amount WHERE id = p_from;
  PERFORM pg_sleep(0.5);
  UPDATE r08.accounts SET balance = balance + p_amount WHERE id = p_to;
END $$;
