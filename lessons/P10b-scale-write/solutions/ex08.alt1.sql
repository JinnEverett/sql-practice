ALTER TABLE p10b.big ADD COLUMN amount_big bigint;
SELECT format('UPDATE p10b.big SET amount_big = amount WHERE id > %s AND id <= %s;', g * 5000, g * 5000 + 5000) FROM generate_series(0, 19) g \gexec
