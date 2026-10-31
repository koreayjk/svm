-- Supabase 흉내: 이 저장소의 SQL(01~14)을 보통 Postgres 에서도 돌려 볼 수 있게 최소한만 만듭니다.
-- (진짜 Supabase 에는 이미 있는 것들입니다. 여기서는 테스트 전용)
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin bypassrls; end if;
end $$;
create schema if not exists auth;
grant usage on schema auth to anon, authenticated, service_role;
create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create or replace function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('app.uid', true), '')::uuid $$;
create or replace function auth.role() returns text language sql stable as
  $$ select coalesce(nullif(current_setting('app.role', true), ''), 'anon') $$;
create schema if not exists test;
grant usage on schema test to public;
