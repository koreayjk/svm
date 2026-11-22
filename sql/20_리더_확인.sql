-- =====================================================================
-- 훈련 이중 확인: 학생이 체크하고, 나라 리더(또는 관리자)가 확인해야 "인정"됩니다.
--   여러 번 실행해도 안전합니다. (19번 다음에 실행)
--   - 학생은 확인 표시를 직접 바꿀 수 없고, 확인된 항목은 지울 수 없습니다.
--   - 학생이 설교 노트나 보고서 본문을 고치면 확인이 풀립니다.
--   - 리더는 확인 표시만 바꿀 수 있고, 본인의 기록은 스스로 확인할 수 없습니다.
-- =====================================================================
alter table public.training_progress
  add column if not exists confirmed_by uuid references public.profiles(id) on delete set null,
  add column if not exists confirmed_at timestamptz;
alter table public.training_reports
  add column if not exists confirmed_by uuid references public.profiles(id) on delete set null,
  add column if not exists confirmed_at timestamptz;

create or replace function public.guard_training_progress()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.confirmed_by := null; new.confirmed_at := null;
  elsif auth.uid() is not distinct from old.user_id then
    new.confirmed_by := old.confirmed_by; new.confirmed_at := old.confirmed_at;
    if new.note is distinct from old.note then new.confirmed_by := null; new.confirmed_at := null; end if;
  else
    new.note := old.note; new.done_at := old.done_at; new.user_id := old.user_id; new.track := old.track; new.item := old.item;
    if new.confirmed_at is not null then
      new.confirmed_by := auth.uid();
      if old.confirmed_at is not null then new.confirmed_at := old.confirmed_at; new.confirmed_by := old.confirmed_by; end if;
    else new.confirmed_by := null; end if;
  end if;
  return new;
end $$;
drop trigger if exists guard_training_progress on public.training_progress;
create trigger guard_training_progress before insert or update on public.training_progress
  for each row execute function public.guard_training_progress();

create or replace function public.guard_training_report()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.leader_comment := null; new.submitted_at := now(); new.updated_at := now();
    new.confirmed_by := null; new.confirmed_at := null;
  elsif auth.uid() is not distinct from old.user_id then
    new.leader_comment := old.leader_comment; new.submitted_at := old.submitted_at; new.updated_at := now();
    new.confirmed_by := old.confirmed_by; new.confirmed_at := old.confirmed_at;
    if new.body is distinct from old.body then new.confirmed_by := null; new.confirmed_at := null; end if;
  else
    new.body := old.body; new.submitted_at := old.submitted_at; new.updated_at := old.updated_at;
    if new.confirmed_at is not null then
      new.confirmed_by := auth.uid();
      if old.confirmed_at is not null then new.confirmed_at := old.confirmed_at; new.confirmed_by := old.confirmed_by; end if;
    else new.confirmed_by := null; end if;
  end if;
  return new;
end $$;

drop policy if exists "training: leader confirm" on public.training_progress;
create policy "training: leader confirm" on public.training_progress for update
  using (public.is_my_trainee(user_id) and user_id <> auth.uid())
  with check (public.is_my_trainee(user_id) and user_id <> auth.uid());

-- 확인된 항목은 학생이 지울 수 없다 (리더가 먼저 확인을 풀어야 함)
drop policy if exists "training: self delete" on public.training_progress;
create policy "training: self delete" on public.training_progress for delete using (user_id = auth.uid() and confirmed_at is null);

-- 보고서: 리더가 확인 표시를 바꾸려면 본인 것이 아니어야 한다
drop policy if exists "report: edit" on public.training_reports;
create policy "report: edit" on public.training_reports for update
  using (user_id = auth.uid() or (public.is_my_trainee(user_id)))
  with check (user_id = auth.uid() or (public.is_my_trainee(user_id)));
