BEGIN;
:ans
;
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.vat_incl(100000)$$) = '108000', 'vat_incl(100000) = 108000 (mặc định 8%)');
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.vat_incl(100000, 0.1)$$) = '110000', 'vat_incl(100000, 0.1) = 110000');
SELECT pg_temp.ck(pg_temp.val($$SELECT i09.vat_incl(99999, 0.08)$$) = '107999', 'làm tròn về số nguyên (99999 × 1.08 = 107998.92 → 107999)');
SELECT pg_temp.ck(pg_temp.val($$SELECT coalesce(i09.vat_incl(NULL)::text, 'null')$$) = 'null', 'đối số NULL → NULL');
SELECT pg_temp.ck((SELECT provolatile FROM pg_proc WHERE oid = 'i09.vat_incl(numeric,numeric)'::regprocedure) = 'i', 'hàm là IMMUTABLE');
SELECT pg_temp.ck((SELECT proisstrict FROM pg_proc WHERE oid = 'i09.vat_incl(numeric,numeric)'::regprocedure), 'hàm là STRICT');
SELECT pg_temp.ck(pg_temp.ok($$CREATE INDEX tmp_vat ON i09.orders (i09.vat_incl(total))$$), 'tạo được index trên i09.vat_incl(total)');
ROLLBACK;
