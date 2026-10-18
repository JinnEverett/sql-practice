CREATE FUNCTION o01.find_customer(p_email text, p_order_by text DEFAULT 'id')
RETURNS TABLE (id int, name text) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT c.id, c.name FROM o01.customers c WHERE c.email = ''' || replace(p_email, '''', '') || ''' ORDER BY ' || p_order_by;
END $$;
