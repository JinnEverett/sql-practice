-- show-output
INSERT INTO f08.products (sku, name, price, stock) VALUES ('P-011','Đế tản nhiệt',150000,30), ('P-012','Pad chuột',60000,0) RETURNING id, sku;
