CREATE OR REPLACE VIEW i09.v_order_summary AS
SELECT o.id AS order_id, c.name AS customer_name, o.status, o.total
FROM i09.orders o JOIN i09.customers c ON c.id = o.customer_id;
