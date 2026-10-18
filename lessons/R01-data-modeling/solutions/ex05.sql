-- db: lab
-- mode: check
-- reset
-- Giải thích: quan hệ nhiều-nhiều = bảng nối với PK ghép (product_id, tag_id) → một cặp chỉ xuất hiện một lần.
--   Xóa sản phẩm thì các dòng nối tự mất (ON DELETE CASCADE) nhưng tag vẫn còn; xóa tag đang dùng thì bị chặn (RESTRICT mặc định).
--   Tên tag không phân biệt hoa/thường: unique index trên lower(name) (extension citext là cách khác).
-- Bẫy: UNIQUE (name) không chặn 'Hot' và 'hot'; bảng nối không có PK → gắn trùng tag; quên index cho tag_id (tìm "sản phẩm theo tag" sẽ Seq Scan).
CREATE TABLE r01.tags (
  id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL CHECK (name = btrim(name) AND name <> '')
);
CREATE UNIQUE INDEX tags_name_uq ON r01.tags (lower(name));
CREATE TABLE r01.product_tags (
  product_id int NOT NULL REFERENCES r01.catalog ON DELETE CASCADE,
  tag_id     int NOT NULL REFERENCES r01.tags,
  PRIMARY KEY (product_id, tag_id)
);
CREATE INDEX product_tags_tag_idx ON r01.product_tags (tag_id);
