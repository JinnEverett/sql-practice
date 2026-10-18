-- sai: không dùng key → mỗi lần gọi (retry) tạo thêm một payment
CREATE FUNCTION r03.charge(p_key text, p_order bigint, p_amount numeric) RETURNS bigint
LANGUAGE sql AS $$ INSERT INTO r03.pay2 (order_id, amount) VALUES (p_order, p_amount) RETURNING id $$;
