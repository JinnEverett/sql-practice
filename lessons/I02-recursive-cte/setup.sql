-- I02 · dữ liệu cây và đồ thị nhỏ. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS i02 CASCADE;
CREATE SCHEMA i02;

-- ex05: sơ đồ tổ chức (cây đúng nghĩa: 1 gốc, không vòng)
CREATE TABLE i02.employees (id int PRIMARY KEY, full_name text NOT NULL, title text NOT NULL, manager_id int REFERENCES i02.employees (id));
INSERT INTO i02.employees VALUES
  (1,  'Minh',  'CEO', NULL),
  (2,  'An',    'CTO', 1),
  (3,  'Bình',  'CFO', 1),
  (4,  'Chi',   'COO', 1),
  (5,  'Dũng',  'Dev lead', 2),
  (6,  'Em',    'QA lead', 2),
  (7,  'Giang', 'Developer', 5),
  (8,  'Hà',    'Developer', 5),
  (9,  'Khoa',  'Developer', 5),
  (10, 'Lan',   'Tester', 6),
  (11, 'Mai',   'Kế toán', 3),
  (12, 'Nam',   'Kế toán', 3),
  (13, 'Oanh',  'Vận hành', 4),
  (14, 'Phúc',  'Intern', 7),
  (15, 'Quân',  'Sales', 4);

-- ex06: dữ liệu nhập tay bị lỗi, có vòng quản lý
CREATE TABLE i02.emp_import (id int PRIMARY KEY, full_name text NOT NULL, manager_id int);
INSERT INTO i02.emp_import VALUES
  (20, 'Tâm',  22),
  (21, 'Uyên', 20),
  (22, 'Vinh', 21),
  (23, 'Xuân', 20),
  (24, 'Yến',  NULL),
  (25, 'Ánh',  24),
  (26, 'Bảo',  26),
  (27, 'Cường', 23);

-- ex07: chuyến bay một chiều (có hướng)
CREATE TABLE i02.flights (src text, dst text, price int, PRIMARY KEY (src, dst));
INSERT INTO i02.flights VALUES
  ('SGN','HAN',1800000), ('SGN','DAD',700000), ('DAD','HAN',600000), ('SGN','CXR',500000),
  ('CXR','DAD',300000),  ('CXR','HAN',1100000), ('SGN','PQC',400000), ('PQC','HPH',900000),
  ('HPH','HAN',200000),  ('DAD','SGN',650000),  ('HAN','SGN',1700000), ('VCA','SGN',300000),
  ('DAD','CXR',250000),  ('SGN','VCA',200000),  ('VCA','CXR',150000), ('CXR','PQC',350000);

-- ex08: định mức vật tư (bill of materials): để làm 1 parent cần qty child
CREATE TABLE i02.bom (parent text, child text, qty int NOT NULL, PRIMARY KEY (parent, child));
INSERT INTO i02.bom VALUES
  ('Laptop', 'Mainboard', 1), ('Laptop', 'Màn hình', 1), ('Laptop', 'RAM', 2), ('Laptop', 'Pin', 1),
  ('Laptop', 'Ốc vít', 6),    ('Laptop', 'Quạt tản nhiệt', 2),
  ('Mainboard', 'CPU', 1),    ('Mainboard', 'Tụ điện', 4), ('Mainboard', 'Ốc vít', 10),
  ('Màn hình', 'Tấm LCD', 1), ('Màn hình', 'Ốc vít', 4),
  ('Pin', 'Cell pin', 3),
  ('Quạt tản nhiệt', 'Ốc vít', 2), ('Quạt tản nhiệt', 'Động cơ quạt', 1);
