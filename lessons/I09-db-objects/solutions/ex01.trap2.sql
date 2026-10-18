CREATE TABLE i09.v_orders_vn AS
SELECT o.id AS order_id, c.name AS customer_name, o.status, o.total, (o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS order_date
FROM i09.orders o JOIN i09.customers c ON c.id = o.customer_id WHERE o.status <> 'cancelled';
