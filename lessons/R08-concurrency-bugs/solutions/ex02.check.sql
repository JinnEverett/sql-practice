CREATE EXTENSION IF NOT EXISTS dblink;
:ans
;
-- Tuần tự: sản phẩm 2 có 3 hàng
SELECT r08.reserve(2, 2) AS r1 \gset
SELECT r08.reserve(2, 2) AS r2 \gset
SELECT r08.reserve(2, 1) AS r3 \gset
SELECT pg_temp.ck(:'r1' = 't' AND :'r2' = 'f' AND :'r3' = 't', 'tuần tự: mua 2 được, mua thêm 2 bị từ chối (còn 1), mua 1 được (' || :'r1' || :'r2' || :'r3' || ')');
SELECT pg_temp.ck((SELECT stock FROM r08.products WHERE id = 2) = 0 AND (SELECT count(*) FROM r08.orders WHERE product_id = 2) = 2, 'tồn kho sản phẩm 2 về 0 và có đúng 2 đơn');
SELECT pg_temp.ck(r08.reserve(999, 1) IS NOT TRUE, 'sản phẩm không tồn tại: trả false, không lỗi');
-- Đồng thời: sản phẩm 1 có 2 hàng, 4 khách tranh nhau; mỗi session giữ transaction mở 0.6 giây sau khi gọi hàm
SELECT pg_temp.bg_start('s1', 'BEGIN; SELECT r08.reserve(1, 1); SELECT pg_sleep(0.6); COMMIT');
SELECT pg_sleep(0.1);
SELECT pg_temp.bg_start('s2', 'BEGIN; SELECT r08.reserve(1, 1); SELECT pg_sleep(0.6); COMMIT');
SELECT pg_sleep(0.1);
SELECT pg_temp.bg_start('s3', 'BEGIN; SELECT r08.reserve(1, 1); SELECT pg_sleep(0.6); COMMIT');
SELECT pg_sleep(0.1);
SELECT pg_temp.bg_start('s4', 'BEGIN; SELECT r08.reserve(1, 1); SELECT pg_sleep(0.6); COMMIT');
SELECT pg_temp.bg_wait('s1') AS w1 \gset
SELECT pg_temp.bg_wait('s2') AS w2 \gset
SELECT pg_temp.bg_wait('s3') AS w3 \gset
SELECT pg_temp.bg_wait('s4') AS w4 \gset
SELECT pg_temp.ck(:'w1' !~ 'ERROR' AND :'w2' !~ 'ERROR' AND :'w3' !~ 'ERROR' AND :'w4' !~ 'ERROR', 'không session nào gặp lỗi (hết hàng phải trả false chứ không ném lỗi): ' || :'w1' || ' / ' || :'w2' || ' / ' || :'w3' || ' / ' || :'w4');
SELECT pg_temp.ck((SELECT stock FROM r08.products WHERE id = 1) = 0, '4 khách tranh 2 hàng: tồn kho về đúng 0 (không âm)');
SELECT pg_temp.ck((SELECT count(*) FROM r08.orders WHERE product_id = 1) = 2, 'có đúng 2 đơn cho sản phẩm 1 (thực tế ' || (SELECT count(*) FROM r08.orders WHERE product_id = 1) || ')');
