-- sai: <= và >= đưa chính nút 34 vào danh sách tổ tiên, và công thức đếm lệch
SELECT a.id, a.name, (a.rgt - a.lft) / 2 AS n_descendants
FROM r06.cat_ns a JOIN r06.cat_ns n ON n.id = 34 AND a.lft <= n.lft AND a.rgt >= n.rgt
ORDER BY a.lft;
