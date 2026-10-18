-- cách đúng khác: unique index trên biểu thức (dùng được cả trước Postgres 15)
CREATE UNIQUE INDEX price_list_uq ON r01.price_list (product_id, coalesce(region, ''));
