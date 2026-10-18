-- sai: sửa path nhưng quên parent_id
UPDATE r06.cat_lt
SET path = (SELECT path FROM r06.cat_lt WHERE id = 3) || subpath(path, nlevel((SELECT path FROM r06.cat_lt WHERE id = 16)) - 1)
WHERE path <@ (SELECT path FROM r06.cat_lt WHERE id = 16);
