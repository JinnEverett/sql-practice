-- P06 · dữ liệu cho ex01–ex06. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS p06 CASCADE;
CREATE SCHEMA p06;

-- tài khoản (ex01, ex03, ex04)
CREATE TABLE p06.acct (id int PRIMARY KEY, balance int NOT NULL CHECK (balance >= 0));
INSERT INTO p06.acct VALUES (1, 100), (2, 50);

-- ghi lại các lần đọc của session A (ex03, ex05)
CREATE TABLE p06.reads (step int, val int);

-- ex02: nhập lô, mã SKU không được trùng
CREATE TABLE p06.sku (code text PRIMARY KEY, name text NOT NULL);
INSERT INTO p06.sku VALUES ('A1', 'ban đầu');

-- ex05: đơn đang mở
CREATE TABLE p06.ticket (id int PRIMARY KEY, status text NOT NULL);
INSERT INTO p06.ticket VALUES (1, 'open'), (2, 'open'), (3, 'closed');

-- ex06: bác sĩ trực; quy tắc nghiệp vụ: luôn có ít nhất 1 người đang trực
CREATE TABLE p06.doctor (id int PRIMARY KEY, name text NOT NULL, on_call boolean NOT NULL);
INSERT INTO p06.doctor VALUES (1, 'An', true), (2, 'Bình', true);
