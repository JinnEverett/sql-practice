SELECT pg_temp.ck(pg_temp.val(:'ans') = '300', 'đếm đúng 300 tài liệu dài');
CREATE TEMP TABLE p AS SELECT pg_temp.plan(:'ans') AS p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 200, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 200: không kéo TOAST)') FROM p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 1, 'kết quả 1 dòng') FROM p;
