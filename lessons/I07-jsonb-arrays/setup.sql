-- I07 · bảng nhỏ để luyện sửa jsonb (ex08). Chạy trên DB `lab`. Chạy lại được nhiều lần.
DROP SCHEMA IF EXISTS i07 CASCADE;
CREATE SCHEMA i07;
CREATE TABLE i07.products (id int PRIMARY KEY, name text NOT NULL, attributes jsonb NOT NULL DEFAULT '{}');
INSERT INTO i07.products VALUES
  (1, 'Tai nghe A', '{"color": "đen", "weight_g": 250, "warranty_months": 24}'),
  (2, 'Áo thun B',  '{"color": "trắng", "size": "M", "weight_g": 180}'),
  (3, 'Áo thun C',  '{"color": "xám", "size": null, "weight_g": 175}'),
  (4, 'Sạc D',      '{"weight_g": 95, "warranty_months": 6}'),
  (5, 'Sách E',     '{}'),
  (6, 'Loa F',      '{"color": "đỏ", "size": null, "weight_g": 1250, "warranty_months": 12}');
