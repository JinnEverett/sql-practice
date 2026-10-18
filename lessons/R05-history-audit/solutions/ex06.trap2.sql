-- sai: UPDATE đè giá lên dòng hiện tại → mất lịch sử
UPDATE r05.price_history SET price = 160 WHERE product_id = 1 AND valid_to IS NULL;
