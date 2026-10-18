ALTER TABLE f09.imports ALTER COLUMN price TYPE numeric(12,2) USING replace(trim(price), '.', '')::numeric;
ALTER TABLE f09.imports ADD CHECK (price >= 0);
