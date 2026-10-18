-- sai: chỉ chặn cha = chính nó, bỏ sót chu trình dài
CREATE FUNCTION r06.no_cycle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.parent_id = NEW.id THEN RAISE EXCEPTION 'tự làm cha' USING ERRCODE = 'check_violation'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER cat_no_cycle BEFORE INSERT OR UPDATE OF parent_id ON r06.cat FOR EACH ROW EXECUTE FUNCTION r06.no_cycle();
