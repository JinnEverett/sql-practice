ALTER TABLE f09.imports ALTER COLUMN price TYPE numeric(12,2) USING regexp_replace(price, '[^0-9]', '', 'g')::numeric;
