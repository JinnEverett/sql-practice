BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT count(*) FROM information_schema.columns WHERE table_schema = 'p01' AND table_name = 'pad_good') = 6, 'pad_good có đúng 6 cột');
SELECT pg_temp.ck((SELECT string_agg(column_name || ':' || data_type, ',' ORDER BY column_name) FROM information_schema.columns WHERE table_schema = 'p01' AND table_name = 'pad_good')
                  = 'a:boolean,b:bigint,c:boolean,d:bigint,e:boolean,f:smallint', 'đúng tên cột và kiểu (b, d vẫn bigint)');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO p01.pad_good (a, b, c, d, e, f) SELECT a, b, c, d, e, f FROM p01.pad_bad$$), 'nạp 50 000 dòng từ pad_bad');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p01.pad_good$$) = '50000', 'đủ 50 000 dòng');
SELECT pg_temp.ck(pg_relation_size('p01.pad_good') <= 0.85 * pg_relation_size('p01.pad_bad'),
                  'pad_good ' || pg_relation_size('p01.pad_good') / 8192 || ' page ≤ 85% của pad_bad ' || pg_relation_size('p01.pad_bad') / 8192 || ' page');
ROLLBACK;
