-- sai: một UPDATE cho toàn bảng (một transaction duy nhất)
CREATE PROCEDURE r10.backfill_status(p_batch int) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r10.orders SET status_code = CASE status WHEN 'pending' THEN 1 WHEN 'paid' THEN 2 WHEN 'shipped' THEN 3 WHEN 'delivered' THEN 4 WHEN 'cancelled' THEN 5 END
  WHERE status_code IS NULL;
END $$;
