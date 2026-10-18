BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.promotions (code, percent, starts_at, ends_at) VALUES ('P10', 10, '2026-10-01+07', '2026-10-31+07')$$), 'chỉ có percent: được');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.promotions (code, amount, starts_at) VALUES ('A50K', 50000, '2026-10-01+07')$$), 'chỉ có amount, vô thời hạn: được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, amount, starts_at) VALUES ('X1', 10, 50000, '2026-10-01+07')$$, '23514'), 'có cả percent lẫn amount bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, starts_at) VALUES ('X2', '2026-10-01+07')$$, '23514'), 'không có percent lẫn amount bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, starts_at) VALUES ('X3', 95, '2026-10-01+07')$$, '23514'), 'percent 95 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, starts_at) VALUES ('X4', 0, '2026-10-01+07')$$, '23514'), 'percent 0 bị chặn');
SELECT pg_temp.ck(pg_temp.ok($$INSERT INTO f09.promotions (code, percent, starts_at) VALUES ('P90', 90, '2026-10-01+07')$$), 'percent 90 (biên) được');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, amount, starts_at) VALUES ('X5', 0, '2026-10-01+07')$$, '23514'), 'amount 0 bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, starts_at, ends_at) VALUES ('X6', 5, '2026-10-10+07', '2026-10-01+07')$$, '23514'), 'ends_at trước starts_at bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, starts_at, ends_at) VALUES ('X7', 5, '2026-10-10+07', '2026-10-10+07')$$, '23514'), 'ends_at = starts_at bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent, starts_at) VALUES ('P10', 5, '2026-10-10+07')$$, '23505'), 'trùng code bị chặn');
SELECT pg_temp.ck(pg_temp.fails($$INSERT INTO f09.promotions (code, percent) VALUES ('X8', 5)$$, '23502'), 'thiếu starts_at bị chặn');
ROLLBACK;
