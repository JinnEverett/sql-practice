-- db: lab
-- mode: check
-- reset
-- Giải thích: HASH partition chia đều dòng cho N partition theo hash(khóa) mod N, khi không có khóa tự nhiên để chia khoảng/danh sách (vd. tenant_id lớn, nhiều giá trị).
--   Mỗi partition khai báo (MODULUS 4, REMAINDER r) với r = 0..3; đủ 4 partition thì phủ kín mọi giá trị, không cần DEFAULT. Cùng tenant_id luôn vào cùng một partition,
--   nên điều kiện `tenant_id = 7` được cắt tỉa còn đúng 1 trong 4 partition. Đổi MODULUS sau này rất đau (phải dựng lại): chọn số lớn hơn nhu cầu hiện tại (lũy thừa của 2 để chia đôi dễ).
-- Bẫy: thiếu một remainder → INSERT lỗi cho các tenant rơi vào remainder đó; hash partition không cắt tỉa được với điều kiện khoảng (tenant_id > 100) hoặc IN không đủ chọn lọc.
CREATE TABLE r12.tenant_logs (
  tenant_id int NOT NULL,
  id        bigint NOT NULL,
  msg       text,
  PRIMARY KEY (tenant_id, id)
) PARTITION BY HASH (tenant_id);
CREATE TABLE r12.tenant_logs_0 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE r12.tenant_logs_1 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE r12.tenant_logs_2 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE r12.tenant_logs_3 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 3);
