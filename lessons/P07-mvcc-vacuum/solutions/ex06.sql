-- db: lab
-- mode: check
-- reset
-- Giải thích: VACUUM thường chỉ freeze tuple có tuổi xid > vacuum_freeze_min_age (50M) nên bảng mới nạp vẫn "all_visible" mà chưa "all_frozen" (0/1 870 page) và relfrozenxid không tiến.
--   VACUUM (FREEZE) freeze mọi tuple: all_frozen = 1 870/1 870 và age(relfrozenxid) về ≈ 0. Làm chủ động ngoài giờ để autovacuum anti-wraparound sau này không có gì để làm (các page đã frozen bị bỏ qua).
-- Bẫy: VACUUM thường (đủ để dọn nhưng không freeze); VACUUM FULL (rewrite cả bảng, khóa, không cần thiết); quên rằng cần superuser/owner.
VACUUM (FREEZE) p07.hist;
