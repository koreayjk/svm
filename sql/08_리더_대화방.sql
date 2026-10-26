-- =====================================================================
-- 리더 대화방: 모든 나라의 선교지 리더(선교사님) · 나라 리더 · 관리자가 함께 쓰는 하나의 방
--   나라별 대화방과 별개 — 나라를 넘어 소식·기도·질문을 나눕니다. 학생에게는 보이지 않습니다.
--   여러 번 실행해도 안전합니다.
-- =====================================================================
create table if not exists public.network_messages (
  id          bigint generated always as identity primary key,
  user_id     uuid references public.profiles(id) on delete set null,
  body        text not null check (length(body) between 1 and 2000),
  created_at  timestamptz not null default now()
);
create index if not exists network_messages_created_idx on public.network_messages(created_at);

-- 이 방에 들어갈 수 있는가? (관리자 · 어느 나라든 리더 · 어느 나라든 선교사님)
create or replace function public.in_network_room()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin()
      or exists (select 1 from public.country_leaders where user_id = auth.uid())
      or exists (select 1 from public.field_partners where user_id = auth.uid());
$$;

alter table public.network_messages enable row level security;
drop policy if exists "network: read" on public.network_messages;
drop policy if exists "network: send" on public.network_messages;
drop policy if exists "network: own delete" on public.network_messages;
create policy "network: read"       on public.network_messages for select using (public.in_network_room());
create policy "network: send"       on public.network_messages for insert with check (user_id = auth.uid() and public.in_network_room());
create policy "network: own delete" on public.network_messages for delete using (user_id = auth.uid() or public.is_admin());

-- 새 메시지가 오면 방의 다른 사람에게 알림
create or replace function public.notify_network_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select distinct u, 'net_msg', '{}'::jsonb, '#/network'
    from (select user_id as u from public.country_leaders
          union select user_id from public.field_partners
          union select id from public.profiles where role = 'admin') x
   where u is not null and u is distinct from new.user_id;
  return new;
end;
$$;
drop trigger if exists notify_network_message on public.network_messages;
create trigger notify_network_message after insert on public.network_messages
  for each row execute function public.notify_network_message();

-- 실시간(Realtime) 구독에 추가 (이미 들어 있으면 건너뜀)
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'network_messages') then
    alter publication supabase_realtime add table public.network_messages;
  end if;
end $$;
