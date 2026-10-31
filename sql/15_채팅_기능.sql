-- =====================================================================
-- 채팅 기본 기능: 답장 · 이모지 반응 · 내 글 수정/삭제 · 사진 첨부
--   나라 채팅방(messages) · 나라별 리더 방(field_messages) · 전체 리더 방(network_messages) 공통.
--   여러 번 실행해도 안전합니다. 사진은 기존 testimony-photos 저장소(본인 폴더)를 씁니다.
-- =====================================================================
alter table public.messages         add column if not exists reply_to bigint references public.messages(id) on delete set null;
alter table public.messages         add column if not exists image_url text check (image_url is null or char_length(image_url) <= 600);
alter table public.messages         add column if not exists edited_at timestamptz;
alter table public.field_messages   add column if not exists reply_to bigint references public.field_messages(id) on delete set null;
alter table public.field_messages   add column if not exists image_url text check (image_url is null or char_length(image_url) <= 600);
alter table public.field_messages   add column if not exists edited_at timestamptz;
alter table public.network_messages add column if not exists reply_to bigint references public.network_messages(id) on delete set null;
alter table public.network_messages add column if not exists image_url text check (image_url is null or char_length(image_url) <= 600);
alter table public.network_messages add column if not exists edited_at timestamptz;

-- 사진만 보내는 메시지는 글이 비어 있어도 됨 (글 길이 제한은 그대로)
do $$ declare t text; c text; lim int; begin
  foreach t in array array['messages','field_messages','network_messages'] loop
    for c in select conname from pg_constraint where conrelid = ('public.' || t)::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%char_length(body)%' and pg_get_constraintdef(oid) not like '%image_url%'
    loop execute format('alter table public.%I drop constraint %I', t, c); end loop;
    lim := case t when 'messages' then 4000 when 'field_messages' then 2000 else 2000 end;
    if not exists (select 1 from pg_constraint where conrelid = ('public.' || t)::regclass and conname = t || '_body_or_image') then
      execute format('alter table public.%I add constraint %I check ((char_length(body) between 1 and %s) or (image_url is not null and char_length(body) between 0 and %s))', t, t || '_body_or_image', lim, lim);
    end if;
  end loop;
end $$;

-- 내 글 수정·삭제: 본인만, 글 내용(body)과 삭제 표시만 바꿀 수 있음
create or replace function public.guard_own_message_edit()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() and new.user_id = old.user_id then
    -- 관리자는 삭제 표시만 (기존 동작)
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
drop trigger if exists guard_own_message_edit on public.messages;
drop trigger if exists guard_own_message_edit on public.field_messages;
drop trigger if exists guard_own_message_edit on public.network_messages;
create trigger guard_own_message_edit before update on public.messages for each row execute function public.guard_own_message_edit();
create trigger guard_own_message_edit before update on public.field_messages for each row execute function public.guard_own_message_edit();
create trigger guard_own_message_edit before update on public.network_messages for each row execute function public.guard_own_message_edit();

drop policy if exists "messages: own update" on public.messages;
create policy "messages: own update" on public.messages for update using (user_id = auth.uid() and not deleted) with check (user_id = auth.uid() and not deleted);
-- 내 글 지우기: "삭제 표시"로 지움. (수정 정책은 지워진 글을 새 값으로 허용하지 않으므로 전용 함수로 처리)
create or replace function public.delete_my_message(mid bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.messages set deleted = true where id = mid and user_id = auth.uid() and not deleted;
  if not found then raise exception 'not your message'; end if;
end;
$$;
revoke all on function public.delete_my_message(bigint) from public, anon;
grant execute on function public.delete_my_message(bigint) to authenticated;
drop policy if exists "field_messages: own update" on public.field_messages;
create policy "field_messages: own update" on public.field_messages for update using (user_id = auth.uid() and public.in_field_room(country_id)) with check (user_id = auth.uid());
drop policy if exists "network: own update" on public.network_messages;
create policy "network: own update" on public.network_messages for update using (user_id = auth.uid() and public.in_network_room()) with check (user_id = auth.uid());
-- 나라 채팅방은 기록을 남기려고 "삭제 표시"로 지움 (본인 글)

-- 이모지 반응 (세 종류의 방 공통)
create table if not exists public.message_reactions (
  id          bigint generated always as identity primary key,
  kind        text not null check (kind in ('room','field','network')),
  message_id  bigint not null,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  emoji       text not null check (emoji in ('👍','❤️','🙏','🎉','😂')),
  created_at  timestamptz not null default now(),
  unique (kind, message_id, user_id, emoji)
);
create index if not exists message_reactions_msg_idx on public.message_reactions(kind, message_id);
alter table public.message_reactions enable row level security;

-- 그 방 메시지를 볼 수 있는 사람만 반응을 보고 남김 (메시지 테이블의 읽기 규칙을 그대로 따름)
create or replace function public.can_see_message(k text, mid bigint)
returns boolean
language sql
stable
as $$
  select case k
    when 'room'    then exists (select 1 from public.messages m where m.id = mid and not m.deleted)
    when 'field'   then exists (select 1 from public.field_messages m where m.id = mid)
    when 'network' then exists (select 1 from public.network_messages m where m.id = mid)
    else false end;
$$;
drop policy if exists "reactions: read" on public.message_reactions;
drop policy if exists "reactions: add" on public.message_reactions;
drop policy if exists "reactions: remove own" on public.message_reactions;
create policy "reactions: read" on public.message_reactions for select to authenticated using (public.can_see_message(kind, message_id));
create policy "reactions: add" on public.message_reactions for insert to authenticated with check (user_id = auth.uid() and public.can_see_message(kind, message_id));
create policy "reactions: remove own" on public.message_reactions for delete to authenticated using (user_id = auth.uid());

-- 답장 알림: 내 글에 답장이 달리면 알림
create or replace function public.notify_chat_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare owner uuid; cc text; cid bigint; lnk text;
begin
  if new.reply_to is null then return new; end if;
  if tg_table_name = 'messages' then
    select user_id into owner from public.messages where id = new.reply_to;
    select code into cc from public.countries where id = new.country_id; lnk := '#/rooms/' || cc;
  elsif tg_table_name = 'field_messages' then
    select user_id into owner from public.field_messages where id = new.reply_to;
    select code into cc from public.countries where id = new.country_id; lnk := '#/network/' || cc;
  else
    select user_id into owner from public.network_messages where id = new.reply_to; lnk := '#/network';
  end if;
  if owner is not null and owner <> new.user_id then
    insert into public.notifications (user_id, kind, payload, link) values (owner, 'chat_reply', '{}'::jsonb, lnk);
  end if;
  return new;
end;
$$;
drop trigger if exists notify_chat_reply on public.messages;
drop trigger if exists notify_chat_reply on public.field_messages;
drop trigger if exists notify_chat_reply on public.network_messages;
create trigger notify_chat_reply after insert on public.messages for each row execute function public.notify_chat_reply();
create trigger notify_chat_reply after insert on public.field_messages for each row execute function public.notify_chat_reply();
create trigger notify_chat_reply after insert on public.network_messages for each row execute function public.notify_chat_reply();

-- 글이 완전히 지워지면 그 글의 반응도 정리
create or replace function public.cleanup_message_reactions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.message_reactions where kind = tg_argv[0] and message_id = old.id;
  return old;
end;
$$;
drop trigger if exists cleanup_reactions on public.messages;
drop trigger if exists cleanup_reactions on public.field_messages;
drop trigger if exists cleanup_reactions on public.network_messages;
create trigger cleanup_reactions after delete on public.messages for each row execute function public.cleanup_message_reactions('room');
create trigger cleanup_reactions after delete on public.field_messages for each row execute function public.cleanup_message_reactions('field');
create trigger cleanup_reactions after delete on public.network_messages for each row execute function public.cleanup_message_reactions('network');

-- 실시간 구독
do $$ declare t text; begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['field_messages','network_messages','message_reactions'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;
