DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM p10b.src LOOP
    INSERT INTO p10b.dst VALUES (r.id, r.v, r.pad);
    COMMIT;
  END LOOP;
END $$;
