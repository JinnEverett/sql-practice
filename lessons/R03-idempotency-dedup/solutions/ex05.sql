-- db: lab
-- mode: check
-- reset
-- Giải thích: idempotency key = client gửi cùng key thì server chỉ làm MỘT lần và trả lại cùng kết quả. Cơ chế an toàn là UNIQUE trên key,
--   không phải "SELECT xem có chưa rồi INSERT" (check-then-act): hai request đồng thời cùng thấy "chưa có" rồi cùng chèn.
--   Cách đúng: INSERT key ON CONFLICT DO NOTHING trước. Request thắng (FOUND) tạo payment; request thua đã CHỜ request thắng commit
--   (khóa chờ trên index unique) nên sau đó đọc được payment_id đã commit.
-- Bẫy: check-then-act → request thứ hai nhận lỗi 23505 (hoặc tệ hơn: tạo 2 payment nếu key không unique); bỏ qua key → mỗi lần retry trừ tiền thêm.
CREATE FUNCTION r03.charge(p_key text, p_order bigint, p_amount numeric) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE v_id bigint;
BEGIN
  INSERT INTO r03.idem_keys (key) VALUES (p_key) ON CONFLICT (key) DO NOTHING;
  IF FOUND THEN
    INSERT INTO r03.pay2 (order_id, amount) VALUES (p_order, p_amount) RETURNING id INTO v_id;
    UPDATE r03.idem_keys SET payment_id = v_id WHERE key = p_key;
    RETURN v_id;
  END IF;
  SELECT payment_id INTO v_id FROM r03.idem_keys WHERE key = p_key;
  RETURN v_id;
END $$;
