SELECT count(*) AS n FROM p01.docs WHERE pg_column_size(body) > 50000;
