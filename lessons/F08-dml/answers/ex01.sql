insert into f08.products (sku,name,price,stock)  values ('P-011', 'Đế tản nhiệt', 150000, 30),
('P-012', 'Pad chuột', 60000, 0)                                                                                                      RETURNING id, sku;
