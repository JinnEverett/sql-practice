-- Dự đoán (bước 1): NULL | false | null | true | null → sai and_false (đúng là false)
select NULL = NULL as null_eq, NULL IS DISTINCT FROM NULL as null_distinct, NULL and false as and_false, NULL or TRUE as or_true, 3 NOT IN (1, 2, NULL) as not_in;
