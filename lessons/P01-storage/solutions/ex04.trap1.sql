SELECT pg_total_relation_size(c.oid) / 8192 AS heap_pages,
       pg_relation_size(c.reltoastrelid) / 8192 AS toast_pages,
       round(100.0 * pg_relation_size(c.reltoastrelid) / (pg_total_relation_size(c.oid) + pg_relation_size(c.reltoastrelid)), 1) AS toast_pct
FROM pg_class c WHERE c.oid = 'p01.docs'::regclass;
