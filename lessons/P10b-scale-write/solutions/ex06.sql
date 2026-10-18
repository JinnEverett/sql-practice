-- db: lab
-- mode: manual
-- Demo: UPDATE toàn bảng trên bản sao của p10.t_m, đo kích thước trước/sau rồi VACUUM (dùng \timing). Chạy script đầy đủ: xem ex06.md.
CREATE SCHEMA IF NOT EXISTS p10b;
DROP TABLE IF EXISTS p10b.upd_demo;
CREATE TABLE p10b.upd_demo AS SELECT * FROM p10.t_m;
ALTER TABLE p10b.upd_demo ADD PRIMARY KEY (id);
SELECT pg_size_pretty(pg_total_relation_size('p10b.upd_demo')) AS before;
UPDATE p10b.upd_demo SET amount = amount + 1;
SELECT pg_size_pretty(pg_total_relation_size('p10b.upd_demo')) AS after_update;
DROP TABLE p10b.upd_demo;
