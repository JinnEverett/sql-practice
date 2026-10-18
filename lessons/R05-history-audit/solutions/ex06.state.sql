SELECT product_id, price, valid_to IS NULL AS is_current, valid_from = now() AS starts_now, valid_to = now() AS ends_now
FROM r05.price_history WHERE product_id = 1 ORDER BY valid_from;
