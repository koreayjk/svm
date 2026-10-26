-- =====================================================================
-- 출발 여정 일정표: 항공편 · 도착 · 귀국 · 마중 · 현지 연락처 (신청서 한 건당 한 줄)
--   본인과 맡은 리더·관리자가 보고 고칩니다. 여러 번 실행해도 안전합니다.
-- =====================================================================
create table if not exists public.application_trips (
  application_id  bigint primary key references public.applications(id) on delete cascade,
  out_flight      text check (out_flight is null or char_length(out_flight) <= 120),
  out_when        text check (out_when is null or char_length(out_when) <= 160),
  arrive_when     text check (arrive_when is null or char_length(arrive_when) <= 160),
  back_flight     text check (back_flight is null or char_length(back_flight) <= 120),
  back_when       text check (back_when is null or char_length(back_when) <= 160),
  meet_note       text check (meet_note is null or char_length(meet_note) <= 500),
  local_contact   text check (local_contact is null or char_length(local_contact) <= 300),
  updated_at      timestamptz not null default now()
);
alter table public.application_trips enable row level security;
drop policy if exists "trips: self or manager read" on public.application_trips;
drop policy if exists "trips: self or manager write" on public.application_trips;
drop policy if exists "trips: self or manager update" on public.application_trips;
create policy "trips: self or manager read" on public.application_trips for select using (
  exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()) or public.can_manage_application(application_id));
create policy "trips: self or manager write" on public.application_trips for insert with check (
  exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()) or public.can_manage_application(application_id));
create policy "trips: self or manager update" on public.application_trips for update
  using (exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()) or public.can_manage_application(application_id))
  with check (exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()) or public.can_manage_application(application_id));
