-- =====================================================================
-- 기도 짝: 같은 나라를 품은 두 사람을 짝지어 서로의 기도 제목을 나눕니다.
--   · 민감 국가는 짝을 만들지 않습니다 (이름이 드러나지 않게)
--   · 짝은 서로만 대화를 봅니다. 차단한 사람과는 짝이 되지 않습니다.
--   여러 번 실행해도 안전합니다.
-- =====================================================================
create table if not exists public.prayer_pairs (
  id          bigint generated always as identity primary key,
  country_id  bigint not null references public.countries(id) on delete cascade,
  user_a      uuid not null references public.profiles(id) on delete cascade,
  user_b      uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  ended_at    timestamptz,
  check (user_a <> user_b)
);
create unique index if not exists prayer_pairs_a_uq on public.prayer_pairs(country_id, user_a) where ended_at is null;
create unique index if not exists prayer_pairs_b_uq on public.prayer_pairs(country_id, user_b) where ended_at is null;

create table if not exists public.prayer_pair_msgs (
  id          bigint generated always as identity primary key,
  pair_id     bigint not null references public.prayer_pairs(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 1000),
  created_at  timestamptz not null default now()
);
create index if not exists prayer_pair_msgs_idx on public.prayer_pair_msgs(pair_id, created_at);

alter table public.prayer_pairs enable row level security;
alter table public.prayer_pair_msgs enable row level security;
drop policy if exists "pairs: members read" on public.prayer_pairs;
drop policy if exists "pairs: members end" on public.prayer_pairs;
drop policy if exists "pair msgs: members read" on public.prayer_pair_msgs;
drop policy if exists "pair msgs: members send" on public.prayer_pair_msgs;
create policy "pairs: members read" on public.prayer_pairs for select using (auth.uid() in (user_a, user_b) or public.is_admin());
create policy "pairs: members end" on public.prayer_pairs for update using (auth.uid() in (user_a, user_b)) with check (auth.uid() in (user_a, user_b));
create policy "pair msgs: members read" on public.prayer_pair_msgs for select using (
  exists (select 1 from public.prayer_pairs p where p.id = pair_id and auth.uid() in (p.user_a, p.user_b)));
create policy "pair msgs: members send" on public.prayer_pair_msgs for insert with check (
  user_id = auth.uid() and exists (select 1 from public.prayer_pairs p where p.id = pair_id and p.ended_at is null and auth.uid() in (p.user_a, p.user_b)));

-- 끝낼 때 끝낸 시각만 바꿀 수 있게
create or replace function public.guard_prayer_pair()
returns trigger
language plpgsql
as $$
begin
  if new.country_id is distinct from old.country_id or new.user_a is distinct from old.user_a or new.user_b is distinct from old.user_b
     or new.created_at is distinct from old.created_at or (old.ended_at is not null and new.ended_at is distinct from old.ended_at) then
    raise exception 'only ending a pairing is allowed';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_prayer_pair on public.prayer_pairs;
create trigger guard_prayer_pair before update on public.prayer_pairs for each row execute function public.guard_prayer_pair();

-- 짝 찾기: 내가 품은 (민감하지 않은) 나라에서 짝이 없는 다른 사람과 이어 줌. 이미 있으면 그 짝을 돌려줌.
create or replace function public.find_prayer_partner(p_country_id bigint)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare me uuid := auth.uid(); pid bigint; other uuid;
begin
  if me is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from public.countries where id = p_country_id and is_active and not is_sensitive) then raise exception 'not available'; end if;
  if not exists (select 1 from public.nation_pledges where user_id = me and country_id = p_country_id) then raise exception 'carry this nation first'; end if;
  select id into pid from public.prayer_pairs where country_id = p_country_id and ended_at is null and me in (user_a, user_b);
  if pid is not null then return pid; end if;
  select np.user_id into other from public.nation_pledges np
   where np.country_id = p_country_id and np.user_id <> me
     and not exists (select 1 from public.prayer_pairs p where p.country_id = p_country_id and p.ended_at is null and np.user_id in (p.user_a, p.user_b))
     and not exists (select 1 from public.user_blocks b where (b.blocker_id = me and b.blocked_id = np.user_id) or (b.blocker_id = np.user_id and b.blocked_id = me))
   order by np.created_at limit 1;
  if other is null then return null; end if;
  insert into public.prayer_pairs (country_id, user_a, user_b) values (p_country_id, other, me) returning id into pid;
  insert into public.notifications (user_id, kind, payload, link)
  values (other, 'pair_new', jsonb_build_object('country_id', p_country_id, 'pair_id', pid), '#/pair/' || pid);
  return pid;
end;
$$;
revoke all on function public.find_prayer_partner(bigint) from public, anon;
grant execute on function public.find_prayer_partner(bigint) to authenticated;

-- 새 글이 오면 짝에게 알림
create or replace function public.notify_pair_msg()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare p record;
begin
  select * into p from public.prayer_pairs where id = new.pair_id;
  insert into public.notifications (user_id, kind, payload, link)
  values (case when p.user_a = new.user_id then p.user_b else p.user_a end, 'pair_msg', jsonb_build_object('country_id', p.country_id, 'pair_id', p.id), '#/pair/' || p.id);
  return new;
end;
$$;
drop trigger if exists notify_pair_msg on public.prayer_pair_msgs;
create trigger notify_pair_msg after insert on public.prayer_pair_msgs for each row execute function public.notify_pair_msg();
