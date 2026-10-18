-- sai: B-tree thường không dùng được cho mẫu có % ở đầu
CREATE INDEX users_fullname_bt ON users (full_name text_pattern_ops);
-- query
SELECT id, full_name FROM users WHERE full_name ILIKE '%nguyễn văn hải%' ORDER BY id;
