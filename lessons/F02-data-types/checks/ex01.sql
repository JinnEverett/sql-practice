-- db: lab
-- ordered
SELECT 0.1::float8 + 0.2::float8         AS float_sum,
       0.1::numeric + 0.2::numeric       AS numeric_sum,
       0.1::float8 + 0.2::float8 = 0.3::float8 AS float_eq,
       0.1::numeric + 0.2::numeric = 0.3 AS numeric_eq;
