-- db: lab
-- mode: check
-- reset
-- Giải thích: DEADLOCK: A giữ khóa tài khoản 1 và đợi tài khoản 2; B giữ khóa tài khoản 2 và đợi tài khoản 1 → vòng chờ. Postgres phát hiện sau deadlock_timeout (mặc định 1 giây)
--   và hủy một giao dịch với lỗi 40P01. Cách sửa gốc: mọi giao dịch luôn khóa tài nguyên THEO CÙNG MỘT THỨ TỰ (ở đây tăng dần theo id), bất kể chiều chuyển.
--   `SELECT … WHERE id IN (from, to) ORDER BY id FOR UPDATE` khóa cả hai dòng, đúng thứ tự, trước khi làm gì khác; sau đó hai UPDATE không phải chờ ai.
--   Giữ nguyên pg_sleep(0.5) mô phỏng xử lý chậm: nó làm lộ lỗi nếu bạn chưa sửa.
-- Bẫy: bắt lỗi 40P01 rồi thử lại (hợp lệ như lớp bảo vệ cuối, nhưng không phải cách sửa); khóa theo thứ tự (from, to) thay vì id.
CREATE OR REPLACE FUNCTION r08.transfer(p_from int, p_to int, p_amount numeric) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM r08.accounts WHERE id IN (p_from, p_to) ORDER BY id FOR UPDATE;
  UPDATE r08.accounts SET balance = balance - p_amount WHERE id = p_from;
  PERFORM pg_sleep(0.5);
  UPDATE r08.accounts SET balance = balance + p_amount WHERE id = p_to;
END $$;
