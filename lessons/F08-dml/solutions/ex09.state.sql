-- ordered
SELECT id, sku, price, stock, is_active, (updated_at > '2026-10-02+07') AS touched FROM f08.products ORDER BY id;
