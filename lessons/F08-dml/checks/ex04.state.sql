-- ordered
SELECT id, sku, stock, price, (updated_at > '2026-10-02+07') AS touched FROM f08.products ORDER BY id;
