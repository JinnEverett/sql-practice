BEGIN;
INSERT INTO p10b.dst SELECT id, v, pad FROM p10b.src WHERE id <= 2500;
INSERT INTO p10b.dst SELECT id, v, pad FROM p10b.src WHERE id > 2500;
COMMIT;
