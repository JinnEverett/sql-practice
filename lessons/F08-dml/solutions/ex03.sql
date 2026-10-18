-- db: lab
-- mode: state
-- Giải thích: Điều kiện đủ 2 vế: is_active AND price < 500000. round(numeric, 0) làm tròn kiểu half-up. updated_at = now() đặt trong cùng SET.
-- Bẫy: Sót is_active → P-007 (ngừng bán) cũng bị tăng giá.
UPDATE f08.products SET price = round(price * 1.10, 0), updated_at = now() WHERE is_active AND price < 500000;
