CREATE EXTENSION IF NOT EXISTS dblink;
-- thêm 60 job sẵn sàng; tổng số job nhận được ban đầu: 1, 2, 3, 7, 8 + 60 = 65
INSERT INTO r04.jobs (payload) SELECT jsonb_build_object('n', i) FROM generate_series(1, 60) i;
SELECT format($w$
DO $d$
DECLARE v bigint;
BEGIN
  LOOP
    EXECUTE %L INTO v;
    EXIT WHEN v IS NULL;
    INSERT INTO r04.log (job_id, worker) VALUES (v, %L);
    PERFORM pg_sleep(0.01);                          -- giả lập công việc
    UPDATE r04.jobs SET status = 'done' WHERE id = v;
  END LOOP;
END $d$
$w$, pg_temp.clean(:'ans'), 'W') AS tpl \gset
SELECT pg_temp.bg_start('w1', replace(:'tpl', '''W''', '''w1'''));
SELECT pg_temp.bg_start('w2', replace(:'tpl', '''W''', '''w2'''));
SELECT pg_temp.bg_start('w3', replace(:'tpl', '''W''', '''w3'''));
SELECT pg_temp.bg_wait('w1') AS r1 \gset
SELECT pg_temp.bg_wait('w2') AS r2 \gset
SELECT pg_temp.bg_wait('w3') AS r3 \gset
SELECT pg_temp.ck(:'r1' !~ '^ERROR' AND :'r2' !~ '^ERROR' AND :'r3' !~ '^ERROR', 'cả 3 worker chạy xong không lỗi');
SELECT pg_temp.ck((SELECT count(*) FROM r04.log) = 65, 'xử lý đủ 65 job (log có ' || (SELECT count(*) FROM r04.log) || ' dòng)');
SELECT pg_temp.ck((SELECT count(DISTINCT job_id) FROM r04.log) = (SELECT count(*) FROM r04.log), 'không job nào bị xử lý hai lần');
SELECT pg_temp.ck((SELECT count(*) FROM r04.jobs WHERE status = 'done' AND id > 11) = 60, '60 job mới đều done');
SELECT pg_temp.ck((SELECT status FROM r04.jobs WHERE id = 4) = 'queued', 'job hẹn giờ tương lai (id 4) không bị nhận');
SELECT pg_temp.ck((SELECT count(*) FROM r04.jobs WHERE status = 'running') = 4, 'các job running có sẵn (5, 9, 10, 11) không bị đụng');
SELECT pg_temp.ck((SELECT max(attempts) FROM r04.jobs WHERE id > 11) = 1, 'mỗi job mới chỉ được nhận đúng 1 lần');
