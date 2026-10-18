select id, amount
from f02.legacy_wallet where amount::numeric = 0.3::numeric
order by id asc;
