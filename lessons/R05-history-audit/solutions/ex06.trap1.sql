-- sai: chỉ INSERT dòng mới, không đóng dòng cũ → hai dòng cùng "hiện tại"
INSERT INTO r05.price_history (product_id, price, valid_from, valid_to) VALUES (1, 160, now(), NULL);
