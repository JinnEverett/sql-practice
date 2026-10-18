-- sai: PK không chứa khóa partition → lỗi 0A000
CREATE TABLE r12.readings (device_id int NOT NULL, ts timestamptz NOT NULL, value numeric(10,2) NOT NULL, PRIMARY KEY (device_id)) PARTITION BY RANGE (ts);
