(select 'đắt' as nhom, id, name, price from products order by price desc limit 5) union (select 'rẻ' as nhom, id, name, price
 from products order by price asc limit 5) order by price desc, id asc;
