-- db: lab
-- mode: check
-- reset
-- Giải thích: oversell xảy ra khi "kiểm tra tồn kho" và "trừ tồn kho" là hai bước tách rời: hai request cùng thấy stock = 1 rồi cùng trừ.
--   Cách chuẩn là một câu UPDATE có điều kiện: UPDATE products SET stock = stock - qty WHERE id = ? AND stock >= qty. Dòng bị khóa thì request sau CHỜ,
--   đọc lại stock mới nhất rồi kiểm điều kiện `stock >= qty` lần nữa: không đủ hàng thì 0 dòng bị sửa (FOUND = false) và ta trả false, không lỗi.
--   Chỉ khi trừ thành công mới ghi đơn. Cả hai thao tác nằm trong một transaction của người gọi, nên thất bại giữa chừng không để lại đơn mồ côi.
-- Bẫy: SELECT stock rồi IF stock >= qty THEN UPDATE (kiểm tra cũ → CHECK stock >= 0 báo lỗi 23514 hoặc, nếu không có CHECK, tồn kho âm);
--   bắt exception CHECK thay vì kiểm điều kiện (chậm, và nuốt lỗi khác).
CREATE FUNCTION r08.reserve(p_product int, p_qty int) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.products SET stock = stock - p_qty WHERE id = p_product AND stock >= p_qty;
  IF NOT FOUND THEN RETURN false; END IF;
  INSERT INTO r08.orders (product_id, qty) VALUES (p_product, p_qty);
  RETURN true;
END $$;
