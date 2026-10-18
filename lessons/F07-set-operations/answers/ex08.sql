select count(*) as n_tong, count(user_id) as n_co_tai_khoan from (select distinct user_id from events union select distinct user_id from orders);
