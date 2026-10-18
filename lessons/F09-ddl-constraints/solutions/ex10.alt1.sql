ALTER TABLE f09.imports ALTER COLUMN price TYPE numeric(12,2) USING translate(price, '. đ', '')::numeric,
  ADD CHECK (price >= 0);
