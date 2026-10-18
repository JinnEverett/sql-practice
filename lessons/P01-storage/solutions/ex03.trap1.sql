SELECT kind, round(avg(octet_length(body)))::int AS avg_len, round(avg(octet_length(body)))::int AS avg_stored,
       count(pg_column_compression(body)) AS n_compressed
FROM p01.docs GROUP BY kind ORDER BY avg_len;
