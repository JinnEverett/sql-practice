-- sai: ADD FOREIGN KEY một phát — quét cả bảng con dưới SHARE ROW EXCLUSIVE
ALTER TABLE r10.child ADD CONSTRAINT child_parent_fk FOREIGN KEY (parent_id) REFERENCES r10.parent (id);
