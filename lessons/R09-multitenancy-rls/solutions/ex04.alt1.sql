-- cách đúng khác: lọc tường minh trong view bằng cùng biểu thức tenant
CREATE OR REPLACE VIEW r09.payment_totals AS
  SELECT tenant_id, count(*) AS n_payments, sum(amount) AS total
  FROM r09.payments
  WHERE tenant_id = nullif(current_setting('app.tenant_id', true), '')::int
  GROUP BY tenant_id;
