-- F07 · dữ liệu nhỏ cho ex10: hai bản export tồn kho. Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS f07 CASCADE;
CREATE SCHEMA f07;
CREATE TABLE f07.stock_a (sku text, warehouse text, qty int);
CREATE TABLE f07.stock_b (sku text, warehouse text, qty int);
INSERT INTO f07.stock_a VALUES
  ('A1','HN',10), ('A2','HN',5), ('A3','HCM',NULL), ('A4','HCM',7), ('A4','HCM',7), ('A5','HN',3);
INSERT INTO f07.stock_b VALUES
  ('A1','HN',10), ('A2','HN',6), ('A3','HCM',NULL), ('A4','HCM',7), ('A6','DN',2);
