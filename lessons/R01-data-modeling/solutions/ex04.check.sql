BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.price_list VALUES (1, NULL, 100000)$$), 'chèn giá toàn quốc cho sản phẩm 1');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.price_list VALUES (1, NULL, 90000)$$, '23505'), 'giá toàn quốc thứ hai cho sản phẩm 1 bị chặn (NULL = NULL)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO r01.price_list VALUES (1, 'HN', 110000), (1, 'HCM', 120000), (2, NULL, 50000)$$), 'giá theo khu vực khác nhau và sản phẩm khác: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO r01.price_list VALUES (1, 'HN', 111000)$$, '23505'), 'trùng (sản phẩm, khu vực) có giá trị bị chặn');
ROLLBACK;
