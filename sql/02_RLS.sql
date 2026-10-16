-- =====================================================================
-- SVM App — 02_RLS.sql
-- 원칙
--   · 본인 데이터는 본인만 수정, 관리자는 전체
--   · testimonies / support_stories 는 approved 만 공개 (작성자·관리자는 pending 도 조회)
--   · applications 는 본인 + 관리자만 조회
--   · 관리자 판별: profiles.role = 'admin' 기반 헬퍼 함수 public.is_admin()
-- 여러 번 실행해도 안전하도록 정책을 drop 후 다시 만듭니다.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 헬퍼 함수
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.setting_bool(k text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select (value)::text::boolean from public.app_settings where key = k), false);
$$;

-- 신청 가능 여부 (require_graduation_to_apply 가 켜지면 수료 회원/관리자만)
create or replace function public.can_apply()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null
     and (not public.setting_bool('require_graduation_to_apply')
          or public.my_role() in ('graduate','admin'));
$$;

create or replace function public.is_team_member(t bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.team_members where team_id = t and user_id = auth.uid());
$$;

-- 게더링 시간(현지 America/Chicago, 시작 30분 전 ~ 종료 30분 후)에만 회원 셀프 체크인 허용
create or replace function public.gathering_open(g bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.gatherings
    where id = g
      and (date + start_time - interval '30 minutes') <= (now() at time zone 'America/Chicago')
      and (date + end_time   + interval '30 minutes') >= (now() at time zone 'America/Chicago')
  );
$$;

-- 앱 클라이언트(authenticated/anon)에서 온 요청인지 — SQL Editor/서비스 키는 예외
create or replace function public.is_client_request()
returns boolean
language sql
stable
as $$
  select current_user in ('authenticated', 'anon');
$$;

-- 채팅·게시판 작성자 이름 표시용 공개 뷰 (전화번호·이메일은 노출하지 않음)
create or replace view public.profile_names as
  select id, name, role from public.profiles;
grant select on public.profile_names to authenticated;

-- 이름 쓰기 표시용 짧은 이름: "이름 + 성 이니셜" (예: "Grace Kim" → "Grace K.")
create or replace function public.short_name(full_name text)
returns text
language sql
immutable
as $$
  select case
    when full_name is null or btrim(full_name) = '' then null
    when array_length(regexp_split_to_array(btrim(full_name), '\s+'), 1) = 1 then btrim(full_name)
    else split_part(btrim(full_name), ' ', 1) || ' ' ||
         upper(left((regexp_split_to_array(btrim(full_name), '\s+'))[array_length(regexp_split_to_array(btrim(full_name), '\s+'), 1)], 1)) || '.'
  end;
$$;

-- 내 나라에 이름 쓰기 — 국가별 품은 사람 수 (민감 국가 포함, 숫자만)
create or replace view public.nation_pledge_counts as
  select c.id as country_id, count(p.user_id)::int as pledge_count
  from public.countries c
  left join public.nation_pledges p on p.country_id = c.id
  group by c.id;
grant select on public.nation_pledge_counts to anon, authenticated;

-- 내 나라에 이름 쓰기 — 이름 목록 (민감 국가는 제외 → 숫자만 공개)
create or replace view public.nation_pledge_names as
  select p.country_id, public.short_name(pr.name) as display_name, p.created_at
  from public.nation_pledges p
  join public.countries c on c.id = p.country_id and not c.is_sensitive
  join public.profiles pr on pr.id = p.user_id
  where pr.name is not null and btrim(pr.name) <> '';
grant select on public.nation_pledge_names to authenticated;

-- ---------------------------------------------------------------------
-- 보호 트리거 — RLS 만으로 막기 어려운 "컬럼 단위" 권한
-- ---------------------------------------------------------------------

-- profiles.role 은 관리자만 변경
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
as $$
begin
  if public.is_client_request() and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.role := 'member';
    elsif new.role is distinct from old.role then
      raise exception 'Only admins can change roles';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_profile_role on public.profiles;
create trigger guard_profile_role before insert or update on public.profiles
  for each row execute function public.guard_profile_role();

-- 승인제 콘텐츠: 일반 회원은 status/featured 를 바꿀 수 없음
create or replace function public.guard_moderated()
returns trigger
language plpgsql
as $$
begin
  if public.is_client_request() and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.status := 'pending';
      if tg_table_name = 'testimonies' then new.featured := false; end if;
    else
      new.status := old.status;
      if tg_table_name = 'testimonies' then new.featured := old.featured; end if;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_moderated on public.testimonies;
create trigger guard_moderated before insert or update on public.testimonies
  for each row execute function public.guard_moderated();
drop trigger if exists guard_moderated on public.support_stories;
create trigger guard_moderated before insert or update on public.support_stories
  for each row execute function public.guard_moderated();

-- 민감 국가 + sensitive_photo_block 설정 시 후기 사진 차단
create or replace function public.guard_sensitive_photos()
returns trigger
language plpgsql
as $$
begin
  if public.is_client_request() and not public.is_admin()
     and coalesce(array_length(new.photos, 1), 0) > 0
     and public.setting_bool('sensitive_photo_block')
     and exists (select 1 from public.countries where id = new.country_id and is_sensitive) then
    raise exception 'Photo uploads are disabled for sensitive countries';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_sensitive_photos on public.testimonies;
create trigger guard_sensitive_photos before insert or update on public.testimonies
  for each row execute function public.guard_sensitive_photos();

-- 강의 피드백: admin_comment 는 관리자만 작성
create or replace function public.guard_feedback()
returns trigger
language plpgsql
as $$
begin
  if public.is_client_request() and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.admin_comment := null;
    else
      new.admin_comment := old.admin_comment;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_feedback on public.course_feedback;
create trigger guard_feedback before insert or update on public.course_feedback
  for each row execute function public.guard_feedback();

-- ---------------------------------------------------------------------
-- RLS 활성화
-- ---------------------------------------------------------------------
alter table public.profiles                   enable row level security;
alter table public.countries                  enable row level security;
alter table public.country_photos             enable row level security;
alter table public.nation_pledges             enable row level security;
alter table public.room_members               enable row level security;
alter table public.messages                   enable row level security;
alter table public.applications               enable row level security;
alter table public.application_status_history enable row level security;
alter table public.application_extensions     enable row level security;
alter table public.gospel_messages            enable row level security;
alter table public.gospel_sentences           enable row level security;
alter table public.language_progress          enable row level security;
alter table public.practice_days              enable row level security;
alter table public.courses                    enable row level security;
alter table public.course_feedback            enable row level security;
alter table public.graduation_requests        enable row level security;
alter table public.teams                      enable row level security;
alter table public.team_members               enable row level security;
alter table public.team_tasks                 enable row level security;
alter table public.team_posts                 enable row level security;
alter table public.gatherings                 enable row level security;
alter table public.attendance                 enable row level security;
alter table public.testimonies                enable row level security;
alter table public.prayers                    enable row level security;
alter table public.prayer_reactions           enable row level security;
alter table public.checklist_items            enable row level security;
alter table public.checklist_progress         enable row level security;
alter table public.support_stories            enable row level security;
alter table public.app_settings               enable row level security;
alter table public.events                     enable row level security;

-- ---------------------------------------------------------------------
-- 정책 일괄 삭제 후 재생성
-- ---------------------------------------------------------------------
do $$
declare r record;
begin
  -- SVM 테이블의 정책만 다시 만듭니다 (같은 Supabase 프로젝트를 쓰는 다른 사이트의 정책은 건드리지 않음)
  for r in select policyname, tablename from pg_policies
           where schemaname = 'public' and tablename = any (array[
             'profiles','countries','country_photos','nation_pledges','room_members','messages','applications',
             'application_status_history','application_extensions','gospel_messages','gospel_sentences',
             'language_progress','practice_days','courses','course_feedback','graduation_requests','teams',
             'team_members','team_tasks','team_posts','gatherings','attendance','testimonies','prayers',
             'prayer_reactions','checklist_items','checklist_progress','support_stories','app_settings','events'])
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- profiles
create policy "profiles: self or admin read"  on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy "profiles: self insert"         on public.profiles for insert with check (id = auth.uid());
create policy "profiles: self or admin update" on public.profiles for update using (id = auth.uid() or public.is_admin())
                                                                         with check (id = auth.uid() or public.is_admin());
create policy "profiles: admin delete"        on public.profiles for delete using (public.is_admin());

-- 공개 콘텐츠: 누구나 읽기, 관리자만 쓰기
create policy "countries: read"        on public.countries      for select using (is_active or public.is_admin());
create policy "countries: admin write" on public.countries      for all using (public.is_admin()) with check (public.is_admin());
create policy "photos: read"           on public.country_photos for select using (true);
create policy "photos: admin write"    on public.country_photos for all using (public.is_admin()) with check (public.is_admin());
create policy "settings: read"         on public.app_settings   for select using (true);
create policy "settings: admin write"  on public.app_settings   for all using (public.is_admin()) with check (public.is_admin());
create policy "events: read"           on public.events         for select using (is_published or public.is_admin());
create policy "events: admin write"    on public.events         for all using (public.is_admin()) with check (public.is_admin());

-- 로그인 회원 읽기, 관리자만 쓰기
create policy "gospel_messages: read"         on public.gospel_messages  for select to authenticated using (is_active or public.is_admin());
create policy "gospel_messages: admin write"  on public.gospel_messages  for all using (public.is_admin()) with check (public.is_admin());
create policy "gospel_sentences: read"        on public.gospel_sentences for select to authenticated using (true);
create policy "gospel_sentences: admin write" on public.gospel_sentences for all using (public.is_admin()) with check (public.is_admin());
create policy "courses: read"                 on public.courses          for select to authenticated using (true);
create policy "courses: admin write"          on public.courses          for all using (public.is_admin()) with check (public.is_admin());
create policy "checklist_items: read"         on public.checklist_items  for select to authenticated using (true);
create policy "checklist_items: admin write"  on public.checklist_items  for all using (public.is_admin()) with check (public.is_admin());
create policy "gatherings: read"              on public.gatherings       for select to authenticated using (true);
create policy "gatherings: admin write"       on public.gatherings       for all using (public.is_admin()) with check (public.is_admin());
create policy "teams: read"                   on public.teams            for select to authenticated using (true);
create policy "teams: admin write"            on public.teams            for all using (public.is_admin()) with check (public.is_admin());
create policy "team_members: read"            on public.team_members     for select to authenticated using (true);
create policy "team_members: admin write"     on public.team_members     for all using (public.is_admin()) with check (public.is_admin());

-- 내 나라에 이름 쓰기: 본인 행만 직접 조회·추가·삭제 (다른 사람은 위의 뷰로 숫자/이름만)
create policy "pledges: self or admin read" on public.nation_pledges for select using (user_id = auth.uid() or public.is_admin());
create policy "pledges: self add"           on public.nation_pledges for insert with check (user_id = auth.uid());
create policy "pledges: self remove"        on public.nation_pledges for delete using (user_id = auth.uid() or public.is_admin());

-- ② 나라방: 참여는 자유 (본인 행만), 메시지는 방 참여자가 작성, 관리자 삭제
create policy "room_members: read"        on public.room_members for select to authenticated using (true);
create policy "room_members: self join"   on public.room_members for insert with check (user_id = auth.uid());
create policy "room_members: self update" on public.room_members for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "room_members: self leave"  on public.room_members for delete using (user_id = auth.uid() or public.is_admin());

create policy "messages: read"         on public.messages for select to authenticated using (not deleted or public.is_admin());
create policy "messages: member write" on public.messages for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.room_members m where m.user_id = auth.uid() and m.country_id = messages.country_id)
);
create policy "messages: admin update" on public.messages for update using (public.is_admin()) with check (public.is_admin());
create policy "messages: admin delete" on public.messages for delete using (public.is_admin());

-- ⑦ 신청: 본인 + 관리자만 조회, 상태 변경은 관리자(미국 본부)만
create policy "applications: self or admin read" on public.applications for select using (user_id = auth.uid() or public.is_admin());
create policy "applications: self submit"        on public.applications for insert with check (
  user_id = auth.uid() and status = 'submitted' and admin_note is null and public.can_apply()
);
create policy "applications: admin update"       on public.applications for update using (public.is_admin()) with check (public.is_admin());
create policy "applications: admin delete"       on public.applications for delete using (public.is_admin());

create policy "app_history: self or admin read" on public.application_status_history for select using (
  public.is_admin() or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid())
);

create policy "extensions: self or admin read" on public.application_extensions for select using (
  public.is_admin() or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid())
);
create policy "extensions: self request" on public.application_extensions for insert with check (
  status = 'pending'
  and exists (select 1 from public.applications a
              where a.id = application_id and a.user_id = auth.uid() and a.status = 'on_field')
);
create policy "extensions: admin update" on public.application_extensions for update using (public.is_admin()) with check (public.is_admin());
create policy "extensions: admin delete" on public.application_extensions for delete using (public.is_admin());

-- ③ 학습 기록: 본인 전체, 관리자 조회
create policy "language_progress: self"       on public.language_progress for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "language_progress: admin read" on public.language_progress for select using (public.is_admin());
create policy "practice_days: self"           on public.practice_days     for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "practice_days: admin read"     on public.practice_days     for select using (public.is_admin());

create policy "feedback: self or admin read" on public.course_feedback for select using (user_id = auth.uid() or public.is_admin());
create policy "feedback: self write"         on public.course_feedback for insert with check (user_id = auth.uid());
create policy "feedback: self or admin edit" on public.course_feedback for update using (user_id = auth.uid() or public.is_admin())
                                                                              with check (user_id = auth.uid() or public.is_admin());
create policy "feedback: admin delete"       on public.course_feedback for delete using (public.is_admin());

create policy "graduation: self or admin read" on public.graduation_requests for select using (user_id = auth.uid() or public.is_admin());
create policy "graduation: self request"       on public.graduation_requests for insert with check (user_id = auth.uid() and status = 'pending');
create policy "graduation: admin update"       on public.graduation_requests for update using (public.is_admin()) with check (public.is_admin());
create policy "graduation: admin delete"       on public.graduation_requests for delete using (public.is_admin());

-- ④ 팀 공간: 팀원 + 관리자
create policy "team_tasks: member read"  on public.team_tasks for select using (public.is_team_member(team_id) or public.is_admin());
create policy "team_tasks: member write" on public.team_tasks for all using (public.is_team_member(team_id) or public.is_admin())
                                                               with check (public.is_team_member(team_id) or public.is_admin());
create policy "team_posts: member read"  on public.team_posts for select using (public.is_team_member(team_id) or public.is_admin());
create policy "team_posts: member write" on public.team_posts for insert with check (user_id = auth.uid() and public.is_team_member(team_id));
create policy "team_posts: own edit"     on public.team_posts for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "team_posts: own or admin delete" on public.team_posts for delete using (user_id = auth.uid() or public.is_admin());

-- ⑤ 출석: 본인 조회 / 게더링 시간에 셀프 체크인, 관리자 전체
create policy "attendance: self or admin read" on public.attendance for select using (user_id = auth.uid() or public.is_admin());
create policy "attendance: self check-in"      on public.attendance for insert with check (
  (user_id = auth.uid() and public.gathering_open(gathering_id)) or public.is_admin()
);
create policy "attendance: admin update" on public.attendance for update using (public.is_admin()) with check (public.is_admin());
create policy "attendance: admin delete" on public.attendance for delete using (public.is_admin());

-- ⑥ 후기: approved 공개, 작성자는 pending 상태에서만 수정
create policy "testimonies: read" on public.testimonies for select using (
  status = 'approved' or user_id = auth.uid() or public.is_admin()
);
create policy "testimonies: self write"  on public.testimonies for insert with check (user_id = auth.uid());
create policy "testimonies: edit"        on public.testimonies for update
  using ((user_id = auth.uid() and status = 'pending') or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy "testimonies: delete"      on public.testimonies for delete using (user_id = auth.uid() or public.is_admin());

-- ⑧ 기도 제목
create policy "prayers: read"   on public.prayers for select to authenticated using (true);
create policy "prayers: write"  on public.prayers for insert with check (user_id = auth.uid());
create policy "prayers: edit"   on public.prayers for update using (user_id = auth.uid() or public.is_admin())
                                                         with check (user_id = auth.uid() or public.is_admin());
create policy "prayers: delete" on public.prayers for delete using (user_id = auth.uid() or public.is_admin());

create policy "prayer_reactions: read"   on public.prayer_reactions for select to authenticated using (true);
create policy "prayer_reactions: add"    on public.prayer_reactions for insert with check (user_id = auth.uid());
create policy "prayer_reactions: remove" on public.prayer_reactions for delete using (user_id = auth.uid());

-- ⑨ 체크리스트 / 후원 사연
create policy "checklist_progress: self"       on public.checklist_progress for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "checklist_progress: admin read" on public.checklist_progress for select using (public.is_admin());

create policy "support: read" on public.support_stories for select using (
  status = 'approved' or user_id = auth.uid() or public.is_admin()
);
create policy "support: self write" on public.support_stories for insert with check (user_id = auth.uid());
create policy "support: edit"       on public.support_stories for update
  using ((user_id = auth.uid() and status = 'pending') or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy "support: delete"     on public.support_stories for delete using (user_id = auth.uid() or public.is_admin());

-- =====================================================================
-- Realtime (채팅) — messages 테이블을 realtime publication 에 추가
-- =====================================================================
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables
                     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- =====================================================================
-- Storage 버킷 & 정책
--   country-photos : 국가 사진 (관리자 업로드, 공개)
--   audio          : 복음 메시지 음성 (관리자 업로드, 공개)
--   testimony-photos : 후기 사진 (회원은 본인 폴더 {user_id}/... 에만 업로드)
-- =====================================================================
do $$ begin
  if exists (select 1 from information_schema.tables where table_schema = 'storage' and table_name = 'buckets') then
    insert into storage.buckets (id, name, public) values
      ('country-photos', 'country-photos', true),
      ('audio', 'audio', true),
      ('testimony-photos', 'testimony-photos', true)
    on conflict (id) do nothing;

    drop policy if exists "svm: public read"          on storage.objects;
    drop policy if exists "svm: admin upload"         on storage.objects;
    drop policy if exists "svm: admin modify"         on storage.objects;
    drop policy if exists "svm: admin remove"         on storage.objects;
    drop policy if exists "svm: member testimony upload" on storage.objects;
    drop policy if exists "svm: member testimony remove" on storage.objects;

    create policy "svm: public read" on storage.objects for select
      using (bucket_id in ('country-photos','audio','testimony-photos'));
    create policy "svm: admin upload" on storage.objects for insert
      with check (bucket_id in ('country-photos','audio','testimony-photos') and public.is_admin());
    create policy "svm: admin modify" on storage.objects for update
      using (bucket_id in ('country-photos','audio','testimony-photos') and public.is_admin());
    create policy "svm: admin remove" on storage.objects for delete
      using (bucket_id in ('country-photos','audio','testimony-photos') and public.is_admin());
    create policy "svm: member testimony upload" on storage.objects for insert to authenticated
      with check (bucket_id = 'testimony-photos' and (storage.foldername(name))[1] = auth.uid()::text);
    create policy "svm: member testimony remove" on storage.objects for delete to authenticated
      using (bucket_id = 'testimony-photos' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
end $$;
