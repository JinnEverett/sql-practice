-- db: lab
-- mode: check
-- reset
-- Giải thích: backfill bảng lớn bằng MỘT câu UPDATE giữ khóa dòng và sinh WAL/bloat trong một transaction dài; replica tụt lại, autovacuum không dọn được trong lúc chạy.
--   Làm theo lô: mỗi vòng sửa tối đa p_batch dòng rồi COMMIT. PROCEDURE (không phải FUNCTION) mới được COMMIT bên trong và phải gọi bằng CALL ngoài transaction.
--   Chọn lô bằng khóa chính tăng dần (WHERE status_code IS NULL ORDER BY id LIMIT p_batch) để mỗi vòng chỉ chạm dòng chưa làm; điều kiện IS NULL làm cho thủ tục chạy lại được (idempotent).
--   Đo bằng xmin: mỗi lô là một transaction nên có xmin riêng và không lô nào vượt p_batch dòng.
-- Bẫy: một UPDATE toàn bảng; quên COMMIT trong vòng lặp (cả thủ tục là một transaction); không có điều kiện IS NULL (làm lại từ đầu mỗi vòng → vòng lặp vô hạn).
CREATE PROCEDURE r10.backfill_status(p_batch int) LANGUAGE plpgsql AS $$
DECLARE n int;
BEGIN
  LOOP
    UPDATE r10.orders o
    SET status_code = CASE o.status WHEN 'pending' THEN 1 WHEN 'paid' THEN 2 WHEN 'shipped' THEN 3 WHEN 'delivered' THEN 4 WHEN 'cancelled' THEN 5 END
    WHERE o.id IN (SELECT id FROM r10.orders WHERE status_code IS NULL ORDER BY id LIMIT p_batch);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0;
    COMMIT;
  END LOOP;
END $$;
