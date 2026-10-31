-- =====================================================================
-- 채팅 고급 기능: @멘션 · 글 고정 · 읽음 표시 (검색과 입력 중 표시는 앱 쪽에서만 처리)
--   sql/15 를 먼저 실행하세요. 여러 번 실행해도 안전합니다.
-- =====================================================================
alter table public.messages         add column if not exists mentions uuid[] not null default '{}' check (coalesce(array_length(mentions, 1), 0) <= 10);
alter table public.field_messages   add column if not exists mentions uuid[] not null default '{}' check (coalesce(array_length(mentions, 1), 0) <= 10);
alter table public.network_messages add column if not exists mentions uuid[] not null default '{}' check (coalesce(array_length(mentions, 1), 0) <= 10);
alter table public.messages         add column if not exists pinned_at timestamptz;
alter table public.messages         add column if not exists pinned_by uuid references public.profiles(id) on delete set null;
alter table public.field_messages   add column if not exists pinned_at timestamptz;
alter table public.field_messages   add column if not exists pinned_by uuid references public.profiles(id) on delete set null;
alter table public.network_messages add column if not exists pinned_at timestamptz;
alter table public.network_messages add column if not exists pinned_by uuid references public.profiles(id) on delete set null;

-- 고치기 규칙에 추가: 멘션은 보낸 뒤 못 바꿈, 고정 표시는 전용 함수로만 바꿈
create or replace function public.guard_own_message_edit()
returns trigger
language plpgsql
as $$
begin
  if new.pinned_at is distinct from old.pinned_at or new.pinned_by is distinct from old.pinned_by then
    if coalesce(current_setting('svm.pin', true), '') <> '1' then raise exception 'use the pin button'; end if;
    return new;
  end if;
  if new.mentions is distinct from old.mentions then raise exception 'mentions cannot be changed'; end if;
  if public.is_admin() and new.user_id = old.user_id then
    if new.body is distinct from old.body or new.image_url is distinct from old.image_url then raise exception 'admins can only hide messages'; end if;
    return new;
  end if;
  if new.user_id is distinct from old.user_id or new.created_at is distinct from old.created_at
     or new.reply_to is distinct from old.reply_to or new.image_url is distinct from old.image_url then
    raise exception 'only the text of your own message can be changed';
  end if;
  if to_jsonb(old) ? 'country_id' and (to_jsonb(new)->>'country_id') is distinct from (to_jsonb(old)->>'country_id') then raise exception 'cannot move a message'; end if;
  if to_jsonb(old) ? 'deleted' and (to_jsonb(old)->>'deleted') = 'true' and (to_jsonb(new)->>'deleted') = 'false' then raise exception 'a deleted message stays deleted'; end if;
  if new.body is distinct from old.body then new.edited_at := now(); end if;
  return new;
end;
$$;

-- 글 고정: 방을 맡은 사람(관리자 · 그 나라 리더/선교사님, 전체 리더 방은 모든 리더)만. 방마다 하나만 고정됨
create or replace function public.set_message_pin(k text, mid bigint, pin boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare cid bigint;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  perform set_config('svm.pin', '1', true);
  if k = 'room' then
    select country_id into cid from public.messages where id = mid and not deleted;
    if cid is null or not public.can_edit_country(cid) then raise exception 'not allowed'; end if;
    update public.messages set pinned_at = null, pinned_by = null where country_id = cid and pinned_at is not null;
    if pin then update public.messages set pinned_at = now(), pinned_by = auth.uid() where id = mid; end if;
  elsif k = 'field' then
    select country_id into cid from public.field_messages where id = mid;
    if cid is null or not public.can_edit_country(cid) then raise exception 'not allowed'; end if;
    update public.field_messages set pinned_at = null, pinned_by = null where country_id = cid and pinned_at is not null;
    if pin then update public.field_messages set pinned_at = now(), pinned_by = auth.uid() where id = mid; end if;
  elsif k = 'network' then
    if not public.in_network_room() or not exists (select 1 from public.network_messages where id = mid) then raise exception 'not allowed'; end if;
    update public.network_messages set pinned_at = null, pinned_by = null where pinned_at is not null;
    if pin then update public.network_messages set pinned_at = now(), pinned_by = auth.uid() where id = mid; end if;
  else raise exception 'unknown room'; end if;
end;
$$;
revoke all on function public.set_message_pin(text, bigint, boolean) from public, anon;
grant execute on function public.set_message_pin(text, bigint, boolean) to authenticated;

-- @멘션 알림: 그 방에 들어올 수 있는 사람에게만
create or replace function public.notify_chat_mention()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare u uuid; cc text; lnk text; ok boolean;
begin
  if coalesce(array_length(new.mentions, 1), 0) = 0 then return new; end if;
  if tg_table_name = 'messages' then select code into cc from public.countries where id = new.country_id; lnk := '#/rooms/' || cc;
  elsif tg_table_name = 'field_messages' then select code into cc from public.countries where id = new.country_id; lnk := '#/network/' || cc;
  else lnk := '#/network'; end if;
  foreach u in array new.mentions loop
    if u = new.user_id then continue; end if;
    if tg_table_name = 'messages' then ok := exists (select 1 from public.room_members where user_id = u and country_id = new.country_id);
    elsif tg_table_name = 'field_messages' then ok := exists (select 1 from public.profiles where id = u and role = 'admin') or exists (select 1 from public.country_leaders where user_id = u and country_id = new.country_id) or exists (select 1 from public.field_partners where user_id = u and country_id = new.country_id);
    else ok := exists (select 1 from public.profiles where id = u and role = 'admin') or exists (select 1 from public.country_leaders where user_id = u) or exists (select 1 from public.field_partners where user_id = u); end if;
    if ok then insert into public.notifications (user_id, kind, payload, link) values (u, 'chat_mention', '{}'::jsonb, lnk); end if;
  end loop;
  return new;
end;
$$;
drop trigger if exists notify_chat_mention on public.messages;
drop trigger if exists notify_chat_mention on public.field_messages;
drop trigger if exists notify_chat_mention on public.network_messages;
create trigger notify_chat_mention after insert on public.messages for each row execute function public.notify_chat_mention();
create trigger notify_chat_mention after insert on public.field_messages for each row execute function public.notify_chat_mention();
create trigger notify_chat_mention after insert on public.network_messages for each row execute function public.notify_chat_mention();

-- 읽음 표시: 나라 채팅방은 room_members.last_read_at 을 그대로 쓰고, 리더 방은 아래 표를 씀 (country_id 0 = 전체 리더 방)
create table if not exists public.chat_reads (
  kind          text not null check (kind in ('field','network')),
  country_id    bigint not null default 0,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  last_read_at  timestamptz not null default now(),
  primary key (kind, country_id, user_id)
);
alter table public.chat_reads enable row level security;
create or replace function public.in_chat_scope(k text, cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select case k when 'field' then public.in_field_room(cid) when 'network' then public.in_network_room() else false end; $$;
drop policy if exists "chat_reads: read" on public.chat_reads;
drop policy if exists "chat_reads: write own" on public.chat_reads;
drop policy if exists "chat_reads: update own" on public.chat_reads;
create policy "chat_reads: read" on public.chat_reads for select to authenticated using (public.in_chat_scope(kind, country_id));
create policy "chat_reads: write own" on public.chat_reads for insert to authenticated with check (user_id = auth.uid() and public.in_chat_scope(kind, country_id));
create policy "chat_reads: update own" on public.chat_reads for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid() and public.in_chat_scope(kind, country_id));

do $$ declare t text; begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['chat_reads','room_members'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;
