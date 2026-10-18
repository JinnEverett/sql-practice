create table f09.customers (
  id bigint primary key generated always as identity,
  email text not null,
  full_name text not null,
  phone text,
  created_at timestamptz not null default current_timestamp,
  constraint customers_email_key unique (email)
);
