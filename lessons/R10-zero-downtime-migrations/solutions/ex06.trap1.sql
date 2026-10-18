-- sai: chỉ đồng bộ một chiều (total → amount_vnd) và không backfill
CREATE FUNCTION r10.sync_amount() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.amount_vnd := NEW.total; RETURN NEW; END $$;
CREATE TRIGGER orders2_sync BEFORE INSERT OR UPDATE ON r10.orders2 FOR EACH ROW EXECUTE FUNCTION r10.sync_amount();
