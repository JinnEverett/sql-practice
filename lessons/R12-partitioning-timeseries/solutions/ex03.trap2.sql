-- sai: không có partition default → 'central' bị từ chối
CREATE TABLE r12.orders_by_region (order_id bigint NOT NULL, region text NOT NULL, amount numeric(12,2) NOT NULL, PRIMARY KEY (order_id, region)) PARTITION BY LIST (region);
CREATE TABLE r12.orders_north PARTITION OF r12.orders_by_region FOR VALUES IN ('north');
CREATE TABLE r12.orders_south PARTITION OF r12.orders_by_region FOR VALUES IN ('south');
