-- sai: trừ trước, ghi đơn bất kể → không bao giờ từ chối (luôn true), chỉ dừng nhờ CHECK ném lỗi
CREATE FUNCTION r08.reserve(p_product int, p_qty int) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE r08.products SET stock = stock - p_qty WHERE id = p_product;
  INSERT INTO r08.orders (product_id, qty) VALUES (p_product, p_qty);
  RETURN true;
END $$;
