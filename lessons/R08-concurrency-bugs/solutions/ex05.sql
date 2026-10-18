-- db: lab
-- mode: check
-- reset
-- Giải thích: WRITE SKEW — hai giao dịch cùng ĐỌC một tập (số bác sĩ đang trực = 2), mỗi giao dịch SỬA một dòng KHÁC nhau (bác sĩ của mình),
--   mỗi cái đều thấy điều kiện "còn ít nhất 1 người trực" đúng với snapshot của mình, nhưng cộng lại thì vi phạm (không còn ai trực). Không dòng nào bị
--   hai giao dịch cùng ghi nên khóa dòng thông thường không phát hiện ra.
--   Cách sửa: biến tập đã đọc thành đối tượng bị khóa — SELECT … FOR UPDATE trên MỌI dòng đang trực trước khi đếm: request sau chờ request trước commit, rồi đếm lại và thấy chỉ còn 1.
--   Cách khác: pg_advisory_xact_lock(key) làm "ổ khóa logic" cho cả bảng; hoặc chạy SERIALIZABLE ở nơi gọi hàm + retry khi gặp 40001 (ex07).
-- Bẫy: đếm rồi UPDATE không khóa (hai session cùng thấy 2); FOR UPDATE chỉ trên dòng của chính mình (không chặn dòng của người kia).
CREATE FUNCTION r08.go_off_call(p_doc int) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v_on_call int;
BEGIN
  PERFORM 1 FROM r08.doctors WHERE on_call FOR UPDATE;                       -- khóa mọi dòng đang trực: các request sau phải xếp hàng
  SELECT count(*) INTO v_on_call FROM r08.doctors WHERE on_call;
  IF v_on_call <= 1 THEN RETURN false; END IF;                               -- người cuối cùng không được nghỉ
  UPDATE r08.doctors SET on_call = false WHERE id = p_doc AND on_call;
  RETURN FOUND;
END $$;
