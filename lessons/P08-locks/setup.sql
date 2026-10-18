-- P08 · dữ liệu cho ex01–ex07. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS p08 CASCADE;
CREATE SCHEMA p08;

CREATE TABLE p08.t (id int PRIMARY KEY, v int NOT NULL);           -- ex01
INSERT INTO p08.t SELECT i, 0 FROM generate_series(1, 10) i;

CREATE TABLE p08.jobs (id int PRIMARY KEY, state text NOT NULL);    -- ex02 hàng đợi việc
INSERT INTO p08.jobs SELECT i, 'new' FROM generate_series(1, 5) i;

CREATE TABLE p08.acct (id int PRIMARY KEY, balance int NOT NULL);   -- ex03
INSERT INTO p08.acct VALUES (1, 100), (2, 100);
CREATE TABLE p08.xfer_log (from_id int NOT NULL, to_id int NOT NULL);

CREATE TABLE p08.big (id int PRIMARY KEY, v int NOT NULL);          -- ex04
INSERT INTO p08.big SELECT i, i FROM generate_series(1, 50000) i;

CREATE TABLE p08.runs (msg text NOT NULL);                          -- ex05
