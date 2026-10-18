SELECT 'o' AS build_table, (SELECT count(*) FROM p03.o) AS build_rows, 1 AS batches_a, 8 AS batches_b, 49 AS temp_written_b;
