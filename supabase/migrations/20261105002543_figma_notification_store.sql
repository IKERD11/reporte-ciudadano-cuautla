create table public.kv_store_66389b89 (
  key text primary key,
  value jsonb not null
);
alter table public.kv_store_66389b89 enable row level security;
revoke all on public.kv_store_66389b89 from public, anon, authenticated;
grant select, insert, update, delete on public.kv_store_66389b89 to service_role;
