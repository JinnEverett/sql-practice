CREATE FUNCTION i09.vat_incl(amount numeric, rate numeric DEFAULT 0.08)
RETURNS numeric LANGUAGE sql
AS $$ SELECT round(amount * (1 + rate), 0) $$;
