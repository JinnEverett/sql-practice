-- sai: NOT VALID nhưng quên VALIDATE
ALTER TABLE r10.child ADD CONSTRAINT child_parent_fk FOREIGN KEY (parent_id) REFERENCES r10.parent (id) NOT VALID;
