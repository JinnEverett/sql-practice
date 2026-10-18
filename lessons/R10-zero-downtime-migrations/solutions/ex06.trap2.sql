-- sai: trigger hai chiều đúng nhưng quên backfill các dòng có sẵn
CREATE FUNCTION r10.sync_amount() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.amount_vnd := coalesce(NEW.amount_vnd, NEW.total); NEW.total := coalesce(NEW.total, NEW.amount_vnd);
  ELSIF NEW.total IS DISTINCT FROM OLD.total AND NEW.amount_vnd IS NOT DISTINCT FROM OLD.amount_vnd THEN NEW.amount_vnd := NEW.total;
  ELSIF NEW.amount_vnd IS DISTINCT FROM OLD.amount_vnd AND NEW.total IS NOT DISTINCT FROM OLD.total THEN NEW.total := NEW.amount_vnd;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER orders2_sync BEFORE INSERT OR UPDATE ON r10.orders2 FOR EACH ROW EXECUTE FUNCTION r10.sync_amount();
