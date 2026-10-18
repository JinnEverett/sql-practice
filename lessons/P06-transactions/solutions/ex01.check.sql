\set ON_ERROR_STOP off
:ans
;
ROLLBACK;
\set ON_ERROR_STOP on
SELECT pg_temp.ck(pg_temp.val($$SELECT balance FROM p06.acct WHERE id = 1$$) = '100', 'tài khoản 1 vẫn 100 (không bị trừ nửa chừng)');
SELECT pg_temp.ck(pg_temp.val($$SELECT balance FROM p06.acct WHERE id = 2$$) = '50', 'tài khoản 2 vẫn 50 (không được cộng nửa chừng)');
