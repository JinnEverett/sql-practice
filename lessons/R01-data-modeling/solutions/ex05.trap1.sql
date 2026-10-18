-- sai: UNIQUE (name) phân biệt hoa/thường, bảng nối không có PK, FK không CASCADE, thiếu index tag_id
CREATE TABLE r01.tags (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE r01.product_tags (product_id int NOT NULL REFERENCES r01.catalog, tag_id int NOT NULL REFERENCES r01.tags);
