-- db: lab
-- mode: state
-- show-output
-- Giải thích: Liệt kê cột, bỏ qua id để identity tự sinh, is_active nhận DEFAULT true. Một câu INSERT nhiều dòng + RETURNING thay vì SELECT lại.
-- Bẫy: Tự điền id (9, 10) cũng ra cùng kết quả hôm nay nhưng làm lệch sequence: lần INSERT sau sẽ đụng PK.
INSERT INTO f08.products (sku, name, price, stock) VALUES ('P-011','Đế tản nhiệt',150000,30), ('P-012','Pad chuột',60000,0) RETURNING id, sku;
