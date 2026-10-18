CREATE VIEW i09.v_active_customers AS
SELECT id, name, email, status FROM i09.customers WHERE status = 'active';
