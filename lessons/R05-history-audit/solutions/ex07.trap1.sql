-- sai: thêm constraint khi dữ liệu còn chồng nhau → lỗi 23P01
ALTER TABLE r05.price_history_bad
  ADD CONSTRAINT price_no_overlap EXCLUDE USING gist (product_id WITH =, tstzrange(valid_from, valid_to) WITH &&);
