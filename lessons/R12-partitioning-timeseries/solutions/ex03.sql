-- db: lab
-- mode: check
-- reset
-- Giải thích: LIST partition: mỗi partition chứa một tập giá trị rời rạc của khóa (ở đây region). Hợp với dữ liệu phân loại ổn định (khu vực, tenant lớn).
--   Hạn chế quan trọng: PK/UNIQUE phải chứa khóa partition, nên PK là (order_id, region) — database KHÔNG thể bảo đảm order_id duy nhất toàn cục
--   (cùng order_id 1 vẫn chèn được ở 'north' và 'south'). Muốn duy nhất toàn cục: sinh id từ một sequence/UUID dùng chung (không phụ thuộc vào ràng buộc) hoặc partition theo chính order_id.
--   Partition DEFAULT hứng giá trị chưa khai báo (region mới) để INSERT không lỗi; nhưng nhớ rằng thêm partition list mới cho giá trị đang nằm trong DEFAULT sẽ thất bại cho đến khi chuyển dòng đi.
-- Bẫy: PRIMARY KEY (order_id) → lỗi 0A000; không có DEFAULT → region lạ bị từ chối; FOR VALUES IN ('north', 'south') gộp hai region vào một partition.
CREATE TABLE r12.orders_by_region (
  order_id bigint NOT NULL,
  region   text NOT NULL,
  amount   numeric(12,2) NOT NULL,
  PRIMARY KEY (order_id, region)
) PARTITION BY LIST (region);
CREATE TABLE r12.orders_north PARTITION OF r12.orders_by_region FOR VALUES IN ('north');
CREATE TABLE r12.orders_south PARTITION OF r12.orders_by_region FOR VALUES IN ('south');
CREATE TABLE r12.orders_other PARTITION OF r12.orders_by_region DEFAULT;
