-- sai: không bỏ dấu phía tên sản phẩm → 'Ốp lưng' không còn giống 'op lung'
SELECT id, name, round(similarity(name, 'op lung samsug')::numeric, 3) AS sim FROM products
WHERE similarity(name, 'op lung samsug') > 0.3 ORDER BY sim DESC, id LIMIT 5;
