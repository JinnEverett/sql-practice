ALTER TABLE p10b.big ADD COLUMN amount_big bigint;
UPDATE p10b.big SET amount_big = amount;
