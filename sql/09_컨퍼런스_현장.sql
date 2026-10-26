-- =====================================================================
-- 컨퍼런스 현장 모드: 접수(체크인) · 현장 등록 · 앱 "도착했어요"
--   여러 번 실행해도 안전합니다.
-- =====================================================================
alter table public.conference_registrations add column if not exists checked_in_at timestamptz;
alter table public.conference_registrations add column if not exists checked_in_by uuid references public.profiles(id) on delete set null;
alter table public.conference_registrations add column if not exists walk_in boolean not null default false;

-- 공개 등록 양식으로는 체크인·현장등록 표시를 넣을 수 없게 (관리자만 가능)
drop policy if exists "registrations: public insert" on public.conference_registrations;
create policy "registrations: public insert" on public.conference_registrations for insert to anon, authenticated
  with check (event_key = 'mc2026' and checked_in_at is null and checked_in_by is null and walk_in = false);

-- 앱에서 "도착했어요"를 누른 사람 (본인 한 번, 관리자만 조회)
create table if not exists public.conference_checkins (
  user_id     uuid primary key references public.profiles(id) on delete cascade,
  event_key   text not null default 'mc2026',
  created_at  timestamptz not null default now()
);
alter table public.conference_checkins enable row level security;
drop policy if exists "conf checkins: own or admin read" on public.conference_checkins;
drop policy if exists "conf checkins: own insert" on public.conference_checkins;
drop policy if exists "conf checkins: admin delete" on public.conference_checkins;
create policy "conf checkins: own or admin read" on public.conference_checkins for select using (user_id = auth.uid() or public.is_admin());
create policy "conf checkins: own insert" on public.conference_checkins for insert with check (user_id = auth.uid() and event_key = 'mc2026');
create policy "conf checkins: admin delete" on public.conference_checkins for delete using (public.is_admin());
