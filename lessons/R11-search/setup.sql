-- R11 · bài báo nhỏ có tiếng Việt có dấu để luyện xếp hạng full-text. Chạy trên DB `lab`. Chạy lại được nhiều lần.
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
DROP SCHEMA IF EXISTS r11 CASCADE;
CREATE SCHEMA r11;
CREATE TABLE r11.articles (id int PRIMARY KEY, title text NOT NULL, body text NOT NULL);
INSERT INTO r11.articles VALUES
  (1,  'Chỉ mục B-tree trong Postgres',      'B-tree là loại chỉ mục mặc định, dùng tốt cho so sánh bằng và khoảng.'),
  (2,  'Tối ưu truy vấn chậm',               'Đọc EXPLAIN trước, sau đó mới chọn chỉ mục phù hợp. Chỉ mục sai làm ghi chậm đi.'),
  (3,  'Giới thiệu Postgres',                'Postgres là hệ quản trị cơ sở dữ liệu mã nguồn mở, ra đời từ thập niên 1980.'),
  (4,  'Sao lưu và khôi phục',               'Dùng pg_dump cho bản sao logic. Kiểm thử khôi phục thường xuyên, không liên quan gì tới chỉ mục.'),
  (5,  'Chỉ mục GIN và GiST',                'GIN hợp với tìm kiếm toàn văn; GiST hợp với dữ liệu hình học. Cả hai đều là chỉ mục đặc biệt.'),
  (6,  'Giao dịch và cô lập',                'Mức cô lập quyết định hiện tượng bạn nhìn thấy khi nhiều phiên cùng ghi.'),
  (7,  'Phân vùng bảng lớn',                 'Phân vùng giúp xóa dữ liệu cũ nhanh và cắt tỉa phân vùng khi truy vấn. Mỗi phân vùng có chỉ mục riêng.'),
  (8,  'Tìm kiếm toàn văn tiếng Việt',       'Tiếng Việt không có stemmer sẵn, dùng cấu hình simple và bỏ dấu bằng unaccent.'),
  (9,  'Quản lý kết nối',                    'PgBouncer giảm số kết nối thật tới Postgres.'),
  (10, 'Chỉ mục một phần',                   'Chỉ mục một phần chỉ lập chỉ mục cho các dòng thỏa điều kiện, nhỏ hơn và nhanh hơn.'),
  (11, 'Thống kê và planner',                'ANALYZE cập nhật thống kê để planner chọn đúng kế hoạch, kể cả khi dùng chỉ mục.'),
  (12, 'Khóa và deadlock',                   'Khóa dòng, khóa bảng và cách tránh deadlock bằng thứ tự khóa cố định.');
