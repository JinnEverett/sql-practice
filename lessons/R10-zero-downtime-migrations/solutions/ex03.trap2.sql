-- sai: chia lô nhưng không COMMIT giữa các lô (cả thủ tục là một transaction)
CREATE PROCEDURE r10.backfill_status(p_batch int) LANGUAGE plpgsql AS $$
DECLARE n int;
BEGIN
  LOOP
    UPDATE r10.orders o SET status_code = CASE o.status WHEN 'pending' THEN 1 WHEN 'paid' THEN 2 WHEN 'shipped' THEN 3 WHEN 'delivered' THEN 4 WHEN 'cancelled' THEN 5 END
    WHERE o.id IN (SELECT id FROM r10.orders WHERE status_code IS NULL ORDER BY id LIMIT p_batch);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0;
  END LOOP;
END $$;
