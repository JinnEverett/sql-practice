SELECT coalesce(pg_sequence_last_value('p03.touch_seq'), 0) AS seq_before \gset
\o /dev/null
:ans
;
\o
SELECT pg_temp.ck(pg_temp.val($$SELECT sum(balance) FROM p03.acct$$) = '100000', 'dữ liệu không đổi (tổng balance = 100000)');
SELECT pg_temp.ck(coalesce(pg_sequence_last_value('p03.touch_seq'), 0) - :seq_before = 100, 'trigger đã chạy ' || (coalesce(pg_sequence_last_value('p03.touch_seq'), 0) - :seq_before) || ' lần (cần đúng 100: UPDATE thực sự đã chạy)');
