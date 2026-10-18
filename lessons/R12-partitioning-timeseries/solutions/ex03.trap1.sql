-- sai: PK không chứa khóa partition → lỗi 0A000
CREATE TABLE r12.orders_by_region (order_id bigint NOT NULL, region text NOT NULL, amount numeric(12,2) NOT NULL, PRIMARY KEY (order_id)) PARTITION BY LIST (region);
