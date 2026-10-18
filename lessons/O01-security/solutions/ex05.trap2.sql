CREATE FUNCTION o01.find_customer(p_email text, p_order_by text DEFAULT 'id')
RETURNS TABLE (id int, name text) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY EXECUTE format('SELECT c.id, c.name FROM o01.customers c WHERE c.email = $1 ORDER BY %I', p_order_by) USING p_email;
END $$;
