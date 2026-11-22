-- =====================================================================
-- 훈련 4트랙: ① 언어(기존) ② Explore 7주 ③ Perspectives 15주 ④ 설교 듣기·노트(126편) + 수료 보고서
--   여러 번 실행해도 안전합니다.
--   - training_progress : 주차/설교 하나를 마쳤다는 기록 (설교는 노트도 함께)
--   - training_reports  : 마지막 수료 보고서 (학생 1명당 1개)
--   - 나라 리더는 자기 나라에 이름을 쓴(nation_pledges) 학생이나 신청한 학생의 진행 상황을 봅니다.
-- =====================================================================
create table if not exists public.training_progress (
  user_id  uuid not null references public.profiles(id) on delete cascade,
  track    text not null check (track in ('explore','perspectives','sermon')),
  item     int  not null check (item between 1 and 200),
  note     text check (note is null or char_length(note) <= 6000),
  done_at  timestamptz not null default now(),
  primary key (user_id, track, item)
);

create table if not exists public.training_reports (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  body           text not null check (char_length(body) between 1 and 12000),
  submitted_at   timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  leader_comment text check (leader_comment is null or char_length(leader_comment) <= 2000)
);

-- 이 학생의 훈련을 볼 수 있는 사람: 관리자, 그 학생이 이름을 쓰거나 신청한 나라의 리더
create or replace function public.is_my_trainee(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin()
      or exists (select 1 from public.nation_pledges p where p.user_id = uid and public.is_country_leader(p.country_id))
      or exists (select 1 from public.applications a where a.user_id = uid and public.is_country_leader(a.country_id));
$$;
revoke all on function public.is_my_trainee(uuid) from public;
grant execute on function public.is_my_trainee(uuid) to authenticated;

alter table public.training_progress enable row level security;
alter table public.training_reports  enable row level security;

drop policy if exists "training: read"        on public.training_progress;
drop policy if exists "training: self write"  on public.training_progress;
drop policy if exists "training: self edit"   on public.training_progress;
drop policy if exists "training: self delete" on public.training_progress;
create policy "training: read"        on public.training_progress for select using (user_id = auth.uid() or public.is_my_trainee(user_id));
create policy "training: self write"  on public.training_progress for insert with check (user_id = auth.uid());
create policy "training: self edit"   on public.training_progress for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "training: self delete" on public.training_progress for delete using (user_id = auth.uid());

drop policy if exists "report: read"        on public.training_reports;
drop policy if exists "report: self write"  on public.training_reports;
drop policy if exists "report: edit"        on public.training_reports;
create policy "report: read"       on public.training_reports for select using (user_id = auth.uid() or public.is_my_trainee(user_id));
create policy "report: self write" on public.training_reports for insert with check (user_id = auth.uid());
create policy "report: edit"       on public.training_reports for update using (user_id = auth.uid() or public.is_my_trainee(user_id))
                                                                         with check (user_id = auth.uid() or public.is_my_trainee(user_id));

-- 학생은 리더 코멘트를 못 바꾸고, 리더는 보고서 본문을 못 바꿉니다.
create or replace function public.guard_training_report()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.leader_comment := null; new.submitted_at := now(); new.updated_at := now();
  elsif auth.uid() = old.user_id then
    new.leader_comment := old.leader_comment; new.submitted_at := old.submitted_at; new.updated_at := now();
  else
    new.body := old.body; new.submitted_at := old.submitted_at; new.updated_at := old.updated_at;
  end if;
  return new;
end $$;
drop trigger if exists guard_training_report on public.training_reports;
create trigger guard_training_report before insert or update on public.training_reports
  for each row execute function public.guard_training_report();

-- 나라 리더·관리자가 훈련생의 언어 연습 진도를 보도록
drop policy if exists "language_progress: leader read" on public.language_progress;
create policy "language_progress: leader read" on public.language_progress for select using (public.is_my_trainee(user_id));

-- 설교를 몇 편 이상 들어야 하는지 (관리자 설정에서 바꿈, 기본 30)
insert into public.app_settings (key, value) values ('sermon_required', to_jsonb(30)) on conflict (key) do nothing;

-- 나라 리더는 자기 나라에 이름을 쓴 학생의 이름·학교도 볼 수 있어야 훈련 현황에 보입니다.
drop policy if exists "profiles: country leader reads pledgers" on public.profiles;
create policy "profiles: country leader reads pledgers" on public.profiles for select using (
  exists (select 1 from public.nation_pledges p where p.user_id = profiles.id and public.is_country_leader(p.country_id))
);
