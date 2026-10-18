-- db: lab
-- mode: check
-- reset
-- Giải thích: PL/pgSQL cho phép rẽ nhánh, biến, ngoại lệ. UPDATE … RETURNING … INTO lấy giá trị mới; nếu không có dòng nào khớp, biến
--   INTO là NULL và FOUND = false (với INTO STRICT thì ném NO_DATA_FOUND). RAISE EXCEPTION … USING ERRCODE đặt mã lỗi để ứng dụng bắt đúng loại lỗi.
--   Lỗi ném ra trong hàm làm hỏng câu lệnh gọi (rollback phần UPDATE của câu đó).
-- Bẫy: quên kiểm tra FOUND (đơn không tồn tại mà hàm trả NULL im lặng); kiểm tra pct sau khi đã UPDATE; làm tròn thiếu (numeric(12,2) tự làm tròn nhưng
--   giá trị trả về không).
CREATE FUNCTION i09.apply_discount(p_order_id int, p_pct numeric)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  v_total numeric(12,2);
BEGIN
  IF p_pct IS NULL OR p_pct < 0 OR p_pct > 50 THEN
    RAISE EXCEPTION 'discount % không hợp lệ (0–50)', p_pct USING ERRCODE = 'invalid_parameter_value';
  END IF;
  UPDATE i09.orders
  SET total = round(total * (1 - p_pct / 100), 2)
  WHERE id = p_order_id AND status IN ('pending', 'paid')
  RETURNING total INTO v_total;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'đơn % không tồn tại hoặc không còn ở trạng thái được giảm giá', p_order_id USING ERRCODE = 'no_data_found';
  END IF;
  RETURN v_total;
END $$;
