-- R06 · dữ liệu cây: bản sao cây danh mục của shop_* (42 nút, sâu 4 tầng) vào DB `lab`. Chạy lại được nhiều lần.
-- Dựng sẵn các biểu diễn khác nhau để mỗi bài dùng đúng một cách:
--   r06.cat               adjacency list (cột path để trống, ex03 điền)
--   r06.cat_lt            adjacency + cột path ltree đã điền sẵn (ex06)
--   r06.cat_closure       closure table RỖNG (ex04 điền)   ·  r06.cat_closure_ready  closure table đã điền (ex05)
--   r06.cat_ns            nested set đã tính sẵn (ex07)
DROP SCHEMA IF EXISTS r06 CASCADE;
CREATE SCHEMA r06;

CREATE TABLE r06.cat (
  id        int PRIMARY KEY,
  parent_id int REFERENCES r06.cat,
  name      text NOT NULL,
  slug      text NOT NULL,
  path      ltree);
INSERT INTO r06.cat (id, parent_id, name, slug) VALUES
  
  (1, NULL, 'Thời trang', 'thoi-trang'),
    (2, NULL, 'Điện tử', 'dien-tu'),
    (3, NULL, 'Nhà cửa & Đời sống', 'nha-cua-doi-song'),
    (4, NULL, 'Sách', 'sach'),
    (5, NULL, 'Thể thao & Dã ngoại', 'the-thao-da-ngoai'),
    (6, NULL, 'Làm đẹp', 'lam-dep'),
    (7, NULL, 'Mẹ & Bé', 'me-va-be'),
    (8, NULL, 'Thực phẩm', 'thuc-pham'),
    (9, 1, 'Áo nam', 'ao-nam'),
    (10, 1, 'Áo nữ', 'ao-nu'),
    (11, 1, 'Giày dép', 'giay-dep'),
    (12, 1, 'Túi xách', 'tui-xach'),
    (13, 2, 'Điện thoại', 'dien-thoai'),
    (14, 2, 'Laptop', 'laptop'),
    (15, 2, 'Phụ kiện điện tử', 'phu-kien-dien-tu'),
    (16, 2, 'Âm thanh', 'am-thanh'),
    (17, 3, 'Nhà bếp', 'nha-bep'),
    (18, 3, 'Nội thất', 'noi-that'),
    (19, 3, 'Trang trí', 'trang-tri'),
    (20, 4, 'Sách tiếng Việt', 'sach-tieng-viet'),
    (21, 4, 'Sách ngoại văn', 'sach-ngoai-van'),
    (22, 5, 'Dụng cụ tập luyện', 'dung-cu-tap-luyen'),
    (23, 5, 'Dã ngoại', 'da-ngoai'),
    (24, 6, 'Chăm sóc da', 'cham-soc-da'),
    (25, 6, 'Trang điểm', 'trang-diem'),
    (26, 7, 'Đồ chơi', 'do-choi'),
    (27, 7, 'Bỉm sữa', 'bim-sua'),
    (28, 8, 'Đồ uống', 'do-uong'),
    (29, 8, 'Đồ khô', 'do-kho'),
    (30, 9, 'Áo thun nam', 'ao-thun-nam'),
    (31, 9, 'Áo sơ mi nam', 'ao-so-mi-nam'),
    (32, 11, 'Giày chạy bộ', 'giay-chay-bo'),
    (33, 11, 'Sandal', 'sandal'),
    (34, 16, 'Tai nghe', 'tai-nghe'),
    (35, 16, 'Loa', 'loa'),
    (36, 15, 'Cáp & sạc', 'cap-sac'),
    (37, 15, 'Ốp lưng', 'op-lung'),
    (38, 20, 'Văn học', 'van-hoc'),
    (39, 20, 'Kinh tế', 'kinh-te'),
    (40, 20, 'Thiếu nhi', 'thieu-nhi'),
    (41, 28, 'Cà phê', 'ca-phe'),
    (42, 28, 'Trà', 'tra');

CREATE TABLE r06.prod (id int PRIMARY KEY, category_id int NOT NULL REFERENCES r06.cat);
INSERT INTO r06.prod (id, category_id) VALUES
  (1, 37), (2, 28), (3, 9), (4, 42), (5, 37), (6, 28), (7, 10), (8, 33), (9, 27), (10, 38), (11, 18), (12, 13), 
  (13, 41), (14, 13), (15, 27), (16, 36), (17, 16), (18, 18), (19, 19), (20, 15), (21, 24), (22, 38), (23, 34), 
  (24, 24), (25, 30), (26, 38), (27, 16), (28, 9), (29, 26), (30, 41), (31, 36), (32, 21), (33, 34), (34, 15), 
  (35, 42), (36, 20), (37, 39), (38, 10), (39, 42), (40, 24), (41, 39), (42, 15), (43, 17), (44, 17), (45, 29), 
  (46, 19), (47, 28), (48, 13), (49, 31), (50, 23), (51, 19), (52, 32), (53, 35), (54, 35), (55, 19), (56, 20), 
  (57, 9), (58, 38), (59, 27), (60, 21), (61, 10), (62, 28), (63, 18), (64, 41), (65, 34), (66, 24), (67, 27), 
  (68, 26), (69, 18), (70, 35), (71, 35), (72, 18), (73, 13), (74, 34), (75, 12), (76, 40), (77, 30), (78, 11), 
  (79, 24), (80, 36), (81, 29), (82, 23), (83, 26), (84, 11), (85, 15), (86, 25), (87, 27), (88, 41), (89, 14), 
  (90, 25), (91, 11), (92, 39), (93, 35), (94, 24), (95, 27), (96, 28), (97, 17), (98, 33), (99, 17), (100, 
  33), (101, 31), (102, 29), (103, 42), (104, 13), (105, 13), (106, 37), (107, 36), (108, 41), (109, 40), (110, 
  12), (111, 17), (112, 24), (113, 17), (114, 16), (115, 13), (116, 14), (117, 19), (118, 28), (119, 18), (120, 
  36), (121, 13), (122, 18), (123, 17), (124, 30), (125, 29), (126, 22), (127, 42), (128, 11), (129, 36), (130, 
  35), (131, 36), (132, 21), (133, 14), (134, 34), (135, 28), (136, 9), (137, 37), (138, 40), (139, 23), (140, 
  21), (141, 39), (142, 20), (143, 9), (144, 15), (145, 14), (146, 21), (147, 40), (148, 16), (149, 13), (150, 
  40), (151, 26), (152, 42), (153, 10), (154, 19), (155, 40), (156, 12), (157, 31), (158, 27), (159, 37), (160, 
  10), (161, 42), (162, 42), (163, 28), (164, 37), (165, 16), (166, 37), (167, 33), (168, 37), (169, 20), (170, 
  32), (171, 37), (172, 13), (173, 42), (174, 16), (175, 22), (176, 15), (177, 26), (178, 23), (179, 22), (180, 
  19), (181, 23), (182, 30), (183, 22), (184, 33), (185, 36), (186, 20), (187, 20), (188, 27), (189, 9), (190, 
  12), (191, 16), (192, 20), (193, 39), (194, 41), (195, 26), (196, 13), (197, 41), (198, 29), (199, 15), (200, 
  26)
;

-- ltree: nhãn là id của nút ('2.16.34' = Điện tử > Âm thanh > Tai nghe)
CREATE TABLE r06.cat_lt AS SELECT id, parent_id, name, slug, path FROM r06.cat;
WITH RECURSIVE t AS (
  SELECT id, id::text::ltree AS p FROM r06.cat WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, t.p || c.id::text FROM r06.cat c JOIN t ON c.parent_id = t.id)
UPDATE r06.cat_lt c SET path = t.p FROM t WHERE t.id = c.id;
ALTER TABLE r06.cat_lt ADD PRIMARY KEY (id);
CREATE INDEX cat_lt_path_gist ON r06.cat_lt USING gist (path);

-- closure table: (ancestor, descendant, depth), gồm cả cặp (n, n, 0)
CREATE TABLE r06.cat_closure (ancestor int NOT NULL, descendant int NOT NULL, depth int NOT NULL, PRIMARY KEY (ancestor, descendant));
CREATE TABLE r06.cat_closure_ready (LIKE r06.cat_closure INCLUDING ALL);
WITH RECURSIVE c AS (
  SELECT id AS ancestor, id AS descendant, 0 AS depth FROM r06.cat
  UNION ALL
  SELECT c.ancestor, k.id, c.depth + 1 FROM c JOIN r06.cat k ON k.parent_id = c.descendant)
INSERT INTO r06.cat_closure_ready SELECT * FROM c;

-- nested set: lft = 2 * thứ_tự_duyệt_trước - độ_sâu - 1 ; rgt = lft + 2 * kích_thước_cây_con - 1 (anh em xếp theo id)
CREATE TABLE r06.cat_ns AS
WITH RECURSIVE walk AS (
  SELECT id, 0 AS depth, ARRAY[id] AS ord FROM r06.cat WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, w.depth + 1, w.ord || c.id FROM r06.cat c JOIN walk w ON c.parent_id = w.id),
numbered AS (SELECT id, depth, row_number() OVER (ORDER BY ord) AS p FROM walk),
sizes AS (SELECT ancestor AS id, count(*) AS sz FROM r06.cat_closure_ready GROUP BY ancestor)
SELECT n.id, c.name, 2 * n.p - n.depth - 1 AS lft, 2 * n.p - n.depth - 1 + 2 * s.sz - 1 AS rgt
FROM numbered n JOIN sizes s USING (id) JOIN r06.cat c USING (id);
ALTER TABLE r06.cat_ns ADD PRIMARY KEY (id);
CREATE INDEX cat_ns_lft_rgt ON r06.cat_ns (lft, rgt);
