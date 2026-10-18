select 0.1::double precision + 0.2::double precision as float_sum, 0.1+0.2 as numeric_sum, (0.1::double precision + 0.2::double precision) = 0.3::float8 as float_eq, 0.1 + 0.2 = 0.3 as numeric_eq;
