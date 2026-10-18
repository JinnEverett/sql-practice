-- db: lab
SELECT NULL = NULL AS null_eq, NULL IS DISTINCT FROM NULL AS null_distinct,
       NULL AND false AS and_false, NULL OR true AS or_true, 3 NOT IN (1, 2, NULL) AS not_in;
