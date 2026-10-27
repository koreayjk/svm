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

-- 이 나라의 SVM 리더인가?
create or replace function public.is_country_leader(cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.country_leaders where country_id = cid and user_id = auth.uid());
$$;
-- 이 신청서를 맡은 사람인가? (관리자 또는 그 나라 리더)
create or replace function public.can_manage_application(aid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin() or exists (
    select 1 from public.applications a join public.country_leaders l on l.country_id = a.country_id
    where a.id = aid and l.user_id = auth.uid());
$$;

-- 이 나라의 선교지 파트너(선교사님)인가? / 이 나라 페이지를 고칠 수 있는가?
create or replace function public.is_field_partner(cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.field_partners where country_id = cid and user_id = auth.uid());
$$;
create or replace function public.can_edit_country(cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select public.is_admin() or public.is_field_partner(cid) or public.is_country_leader(cid); $$;
-- 선교지 대화방에 들어갈 수 있는가? (관리자 · 그 나라 리더 · 선교사님)
create or replace function public.in_field_room(cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select public.is_admin() or public.is_country_leader(cid) or public.is_field_partner(cid); $$;

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

-- 셀프 체크인: 모임 시간(시작 30분 전 ~ 종료 30분 후)에만 출석.
--   주일 오후 모임 행이 아직 없으면 정기 일정(일 14:00–16:00)으로 만들어서 체크인 (관리자가 미리 만들 필요 없음)
create or replace function public.self_check_in()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  g_id bigint;
  local_now timestamp := now() at time zone 'America/Chicago';
begin
  if auth.uid() is null then
    raise exception 'Please log in first.';
  end if;
  select id into g_id from public.gatherings
   where (date + start_time - interval '30 minutes') <= local_now
     and (date + end_time   + interval '30 minutes') >= local_now
   order by date desc, start_time desc limit 1;
  if g_id is null and extract(dow from local_now) = 0 and local_now::time between time '13:30' and time '16:30' then
    insert into public.gatherings (type, date, start_time, end_time, location, title)
    values ('sunday', local_now::date, '14:00', '16:00',
            (select value #>> '{}' from public.app_settings where key = 'gathering_location'), 'Sunday Mission Gathering')
    on conflict (date, type) do nothing
    returning id into g_id;
  end if;
  if g_id is null then
    raise exception 'Check-in opens 30 minutes before the gathering and closes 30 minutes after.';
  end if;
  insert into public.attendance (gathering_id, user_id) values (g_id, auth.uid()) on conflict do nothing;
  return g_id;
end;
$$;
revoke all on function public.self_check_in() from public, anon;
grant execute on function public.self_check_in() to authenticated;

-- 채팅·게시판 작성자 이름 표시용 공개 뷰 (전화번호·이메일은 노출하지 않음)

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

-- 채팅·게시판 작성자 이름: "이름 + 성 이니셜"만 (전체 이름·이메일·전화번호는 노출하지 않음)
create or replace view public.profile_names as
  select id, public.short_name(name) as name, role from public.profiles;
grant select on public.profile_names to authenticated;

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
alter table public.conference_registrations   enable row level security;
alter table public.notifications              enable row level security;
alter table public.application_notes          enable row level security;
alter table public.application_insurance      enable row level security;
alter table public.content_reports            enable row level security;
alter table public.user_blocks                enable row level security;
alter table public.device_tokens              enable row level security;
alter table public.country_leaders            enable row level security;
alter table public.application_messages       enable row level security;
alter table public.field_partners             enable row level security;
alter table public.country_videos             enable row level security;
alter table public.field_messages             enable row level security;
alter table public.application_prep          enable row level security;
alter table public.field_checkins            enable row level security;
alter table public.reminder_log              enable row level security;
alter table public.field_updates            enable row level security;
alter table public.field_plans              enable row level security;
alter table public.newsletter_signups        enable row level security;

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
             'prayer_reactions','checklist_items','checklist_progress','support_stories','app_settings','events','conference_registrations',
             'notifications','application_notes','application_insurance','content_reports','user_blocks','device_tokens','country_leaders','application_messages','field_partners','country_videos','field_messages','application_prep','field_checkins','reminder_log','field_updates','field_plans','newsletter_signups'])
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- profiles
create policy "profiles: self or admin read"  on public.profiles for select using (id = auth.uid() or public.is_admin());
-- 나라 리더는 자기 나라에 신청한 학생의 연락처를 봄
create policy "profiles: country leader reads applicants" on public.profiles for select using (
  exists (select 1 from public.applications a where a.user_id = profiles.id and public.is_country_leader(a.country_id))
);
create policy "profiles: self insert"         on public.profiles for insert with check (id = auth.uid());
create policy "profiles: self or admin update" on public.profiles for update using (id = auth.uid() or public.is_admin())
                                                                         with check (id = auth.uid() or public.is_admin());
create policy "profiles: admin delete"        on public.profiles for delete using (public.is_admin());

-- 공개 콘텐츠: 누구나 읽기, 관리자만 쓰기
create policy "countries: read"        on public.countries      for select using (is_active or public.is_admin());
create policy "countries: admin write" on public.countries      for all using (public.is_admin()) with check (public.is_admin());
-- 선교사님: 자기 나라 소개·사역·생활 정보만 고침 (공개 여부·민감 국가·코드·이름은 아래 트리거가 지킴)
create policy "countries: partner edit" on public.countries for update using (public.can_edit_country(id)) with check (public.can_edit_country(id));
create policy "photos: read"           on public.country_photos for select using (true);
create policy "photos: admin write"    on public.country_photos for all using (public.is_admin()) with check (public.is_admin());
create policy "photos: partner add"    on public.country_photos for insert with check (public.can_edit_country(country_id) and uploaded_by = auth.uid());
create policy "photos: partner remove" on public.country_photos for delete using (public.can_edit_country(country_id));
create policy "videos: read"           on public.country_videos for select using (true);
create policy "videos: edit"           on public.country_videos for all using (public.can_edit_country(country_id)) with check (public.can_edit_country(country_id));
create policy "field_partners: members read" on public.field_partners for select to authenticated using (true);
create policy "field_partners: admin write"  on public.field_partners for all using (public.is_admin()) with check (public.is_admin());
create policy "field_messages: read" on public.field_messages for select using (public.in_field_room(country_id));
create policy "field_messages: send" on public.field_messages for insert with check (user_id = auth.uid() and public.in_field_room(country_id));
create policy "field_messages: own delete" on public.field_messages for delete using (user_id = auth.uid() or public.is_admin());

-- 출발 준비: 본인 신청서만 체크, 리더·관리자는 보기만
create policy "prep: self or manager read" on public.application_prep for select using (
  exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()) or public.can_manage_application(application_id));
create policy "prep: self write" on public.application_prep for insert with check (
  exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()));
create policy "prep: self update" on public.application_prep for update
  using (exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()))
  with check (exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()));
create policy "prep: self delete" on public.application_prep for delete using (
  exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()));

-- 안부 체크인: 선교 중인 본인 신청서에만 남기고, 본인과 맡은 리더·관리자가 봄
create policy "checkins: self or manager read" on public.field_checkins for select using (user_id = auth.uid() or public.can_manage_application(application_id));
create policy "checkins: self send" on public.field_checkins for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid() and a.status = 'on_field'));
-- 선교지 소식: 회원은 읽기, 그 나라 선교사님·리더·관리자만 쓰기
create policy "field_updates: read"   on public.field_updates for select to authenticated using (true);
create policy "field_updates: write"  on public.field_updates for insert with check (user_id = auth.uid() and public.can_edit_country(country_id));
create policy "field_updates: delete" on public.field_updates for delete using (user_id = auth.uid() or public.can_edit_country(country_id));
-- 합의 계획서: 리더·관리자가 쓰고, 선교지는 '보낸' 계획만 보고 동의·수정 요청, 학생은 자기 신청서에 연결된 계획만 봄
create policy "plans: read" on public.field_plans for select using (
  public.is_admin() or public.is_country_leader(country_id)
  or (public.is_field_partner(country_id) and sent_at is not null)
  or exists (select 1 from public.applications a where a.plan_id = field_plans.id and a.user_id = auth.uid()));
create policy "plans: lead add" on public.field_plans for insert with check ((public.is_admin() or public.is_country_leader(country_id)) and created_by = auth.uid());
create policy "plans: update" on public.field_plans for update
  using (public.is_admin() or public.is_country_leader(country_id) or (public.is_field_partner(country_id) and sent_at is not null))
  with check (public.is_admin() or public.is_country_leader(country_id) or (public.is_field_partner(country_id) and sent_at is not null));
create policy "plans: lead delete" on public.field_plans for delete using (public.is_admin() or public.is_country_leader(country_id));
-- reminder_log: 정책 없음 = 앱에서는 접근 불가 (아래 send_reminders 함수만 씁니다)

-- 관리자가 아닌 사람이 나라 정보를 고칠 때 바꿀 수 없는 칸은 원래대로
create or replace function public.guard_country_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    new.code := old.code; new.name_en := old.name_en; new.name_ko := old.name_ko;
    new.is_active := old.is_active; new.is_sensitive := old.is_sensitive; new.sort_order := old.sort_order;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_country_update on public.countries;
create trigger guard_country_update before update on public.countries
  for each row execute function public.guard_country_update();
create policy "settings: read"         on public.app_settings   for select using (true);
create policy "settings: admin write"  on public.app_settings   for all using (public.is_admin()) with check (public.is_admin());
create policy "events: read"           on public.events         for select using (is_published or public.is_admin());
create policy "events: admin write"    on public.events         for all using (public.is_admin()) with check (public.is_admin());

-- 컨퍼런스 등록: 누구나 제출(insert)만, 조회·수정·삭제는 관리자
create policy "registrations: public insert" on public.conference_registrations for insert to anon, authenticated
  with check (event_key = 'mc2026');
-- 소식 받기: 누구나 제출(insert)만, 조회·수정·삭제는 관리자
create policy "newsletter: public insert" on public.newsletter_signups for insert to anon, authenticated with check (true);
create policy "newsletter: admin manage"  on public.newsletter_signups for all using (public.is_admin()) with check (public.is_admin());
-- 알림: 본인 것만 읽고 '읽음' 표시. 만들기는 트리거(security definer)만
create policy "notifications: own read"   on public.notifications for select using (user_id = auth.uid());
create policy "notifications: own update" on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications: own delete" on public.notifications for delete using (user_id = auth.uid());
-- 신청서 내부 메모: 관리자만
create policy "application_notes: admin or leader" on public.application_notes for all
  using (public.can_manage_application(application_id)) with check (public.can_manage_application(application_id));

-- 여행자 보험: 본인(승인 이후 신청서만) 제출·다시 제출, 관리자 확인
create policy "insurance: self or admin read" on public.application_insurance for select using (user_id = auth.uid() or public.can_manage_application(application_id));
create policy "insurance: self submit" on public.application_insurance for insert with check (
  user_id = auth.uid() and status = 'submitted' and admin_note is null and reviewed_at is null
  and exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()
              and a.status in ('approved','preparing','on_field'))
);
create policy "insurance: self resubmit" on public.application_insurance for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and status = 'submitted' and reviewed_at is null);
create policy "insurance: admin update" on public.application_insurance for update using (public.can_manage_application(application_id)) with check (public.can_manage_application(application_id));
create policy "insurance: admin delete" on public.application_insurance for delete using (public.is_admin());

-- 신고: 회원은 보내기만, 관리자만 보고 처리 / 차단: 본인 것만
create policy "reports: member send" on public.content_reports for insert with check (
  reporter_id = auth.uid() and status = 'open' and resolved_at is null
  and (target_user_id is null or target_user_id <> auth.uid())
);
create policy "reports: admin read"   on public.content_reports for select using (public.is_admin());
create policy "reports: admin update" on public.content_reports for update using (public.is_admin()) with check (public.is_admin());
create policy "reports: admin delete" on public.content_reports for delete using (public.is_admin());
create policy "blocks: own" on public.user_blocks for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- 계정 삭제 (앱 안에서 본인이 직접 — 스토어 필수). 관련 기록은 외래키 on delete 로 함께 정리됩니다.
--   저장소 파일(간증 사진·보험 증서)은 앱이 먼저 지운 뒤 이 함수를 부릅니다.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'not signed in'; end if;
  if exists (select 1 from public.profiles where id = me and role = 'admin')
     and (select count(*) from public.profiles where role = 'admin') <= 1 then
    raise exception 'last_admin' using hint = 'Make another member an admin first.';
  end if;
  delete from auth.users where id = me;
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 푸시 기기: 본인 것만 보기. 등록·해제는 아래 함수로만 (같은 폰에서 다른 사람이 로그인하면 토큰을 넘겨받음)
create policy "device_tokens: own read" on public.device_tokens for select using (user_id = auth.uid());
create or replace function public.register_device(p_token text, p_platform text, p_lang text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or coalesce(length(p_token), 0) < 10 or length(p_token) > 4096 then return; end if;
  insert into public.device_tokens (token, user_id, platform, lang, updated_at)
  values (p_token, auth.uid(), case when p_platform in ('ios','android','web') then p_platform end, left(p_lang, 5), now())
  on conflict (token) do update set user_id = excluded.user_id, platform = excluded.platform, lang = excluded.lang, updated_at = now();
end;
$$;
create or replace function public.unregister_device(p_token text)
returns void
language sql
security definer
set search_path = public
as $$ delete from public.device_tokens where token = p_token and user_id = auth.uid(); $$;
revoke all on function public.register_device(text, text, text) from public, anon;
revoke all on function public.unregister_device(text) from public, anon;
grant execute on function public.register_device(text, text, text) to authenticated;
grant execute on function public.unregister_device(text) to authenticated;

create policy "registrations: admin manage"  on public.conference_registrations for all using (public.is_admin()) with check (public.is_admin());

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
create policy "applications: self or admin read" on public.applications for select using (user_id = auth.uid() or public.is_admin() or public.is_country_leader(country_id));
create policy "applications: self submit"        on public.applications for insert with check (
  user_id = auth.uid() and status = 'submitted' and admin_note is null and public.can_apply()
);
create policy "applications: admin update"       on public.applications for update using (public.is_admin()) with check (public.is_admin());
-- 나라 리더: 자기 나라 신청서만 처리 (다른 나라로 옮길 수는 없음)
create policy "applications: leader update"      on public.applications for update using (public.is_country_leader(country_id)) with check (public.is_country_leader(country_id));
create policy "applications: admin delete"       on public.applications for delete using (public.is_admin());

create policy "app_history: self or admin read" on public.application_status_history for select using (
  public.can_manage_application(application_id) or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid())
);

create policy "extensions: self or admin read" on public.application_extensions for select using (
  public.can_manage_application(application_id) or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid())
);
create policy "extensions: self request" on public.application_extensions for insert with check (
  status = 'pending'
  and exists (select 1 from public.applications a
              where a.id = application_id and a.user_id = auth.uid() and a.status = 'on_field')
);
create policy "extensions: admin update" on public.application_extensions for update using (public.can_manage_application(application_id)) with check (public.can_manage_application(application_id));

-- 나라 리더 목록: 로그인한 회원 누구나 보기 (학생이 내 리더를 알 수 있게), 지정은 관리자만
create policy "country_leaders: members read" on public.country_leaders for select to authenticated using (true);
create policy "country_leaders: admin write"  on public.country_leaders for all using (public.is_admin()) with check (public.is_admin());

-- 신청서 대화: 신청한 학생, 그 나라 리더, 관리자만 읽고 씀 (본인 이름으로만)
create policy "app_messages: read" on public.application_messages for select using (
  public.can_manage_application(application_id)
  or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid())
);
create policy "app_messages: send" on public.application_messages for insert with check (
  user_id = auth.uid() and (
    public.can_manage_application(application_id)
    or exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()))
);
create policy "app_messages: own delete" on public.application_messages for delete using (user_id = auth.uid() or public.is_admin());
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
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables
                     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- =====================================================================
-- 앱 안 알림 트리거 — 관리자가 상태를 바꾸거나 답글을 달면 회원에게 알림
-- =====================================================================
create or replace function public.notify_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- 테이블마다 컬럼이 달라서, 테이블 이름으로 먼저 나눈 뒤 각 테이블의 컬럼만 읽습니다
  if tg_table_name = 'applications' then
    if new.status is distinct from old.status then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'app_status', jsonb_build_object('status', new.status, 'country_id', new.country_id), '#/apps/' || new.id);
      if new.status = 'returned' then   -- 돌아오면 후기를 나눠 달라고 초대
        insert into public.notifications (user_id, kind, payload, link)
        values (new.user_id, 'returned_testi', jsonb_build_object('country_id', new.country_id), '#/apps/' || new.id);
      end if;
    end if;
  elsif tg_table_name = 'application_extensions' then
    if new.status is distinct from old.status and new.status <> 'pending' then
      insert into public.notifications (user_id, kind, payload, link)
      select a.user_id, 'ext_status', jsonb_build_object('status', new.status, 'date', new.new_return_date), '#/apps/' || a.id
        from public.applications a where a.id = new.application_id;
    end if;
  elsif tg_table_name = 'application_insurance' then
    if new.status is distinct from old.status and new.status <> 'submitted' then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'ins_status', jsonb_build_object('status', new.status), '#/apps/' || new.application_id);
    end if;
  elsif tg_table_name = 'graduation_requests' then
    if new.status is distinct from old.status and new.status <> 'pending' then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'grad_status', jsonb_build_object('status', new.status), '#/train');
    end if;
  elsif tg_table_name = 'testimonies' then
    if new.status is distinct from old.status and new.status <> 'pending' then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'testi_status', jsonb_build_object('status', new.status, 'title', new.title), '#/testimonies');
    end if;
  elsif tg_table_name = 'support_stories' then
    if new.status is distinct from old.status and new.status <> 'pending' then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'support_status', jsonb_build_object('status', new.status, 'title', new.title), '#/support');
    end if;
  elsif tg_table_name = 'course_feedback' then
    if new.admin_comment is not null and new.admin_comment is distinct from old.admin_comment then
      insert into public.notifications (user_id, kind, payload, link)
      values (new.user_id, 'feedback_reply', jsonb_build_object('course_id', new.course_id), '#/course/' || new.course_id);
    end if;
  end if;
  return new;
end;
$$;

-- 새 신고가 들어오면 관리자 모두에게 알림
create or replace function public.notify_report()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select p.id, 'report_new', jsonb_build_object('kind', new.target_kind, 'reason', new.reason), '#/admin'
    from public.profiles p where p.role = 'admin';
  return new;
end;
$$;

-- 신청서 대화 알림: 리더가 쓰면 학생에게, 학생이 쓰면 그 나라 리더(없으면 관리자)에게
create or replace function public.notify_app_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare a record;
begin
  select id, user_id, country_id into a from public.applications where id = new.application_id;
  if a.id is null then return new; end if;
  if new.user_id is distinct from a.user_id then
    insert into public.notifications (user_id, kind, payload, link)
    values (a.user_id, 'leader_msg', jsonb_build_object('country_id', a.country_id), '#/apps/' || a.id);
  else
    insert into public.notifications (user_id, kind, payload, link)
    select l.user_id, 'student_msg', jsonb_build_object('country_id', a.country_id), '#/lead/' || a.id
      from public.country_leaders l where l.country_id = a.country_id;
    if not found then
      insert into public.notifications (user_id, kind, payload, link)
      select p.id, 'student_msg', jsonb_build_object('country_id', a.country_id), '#/lead/' || a.id
        from public.profiles p where p.role = 'admin';
    end if;
  end if;
  return new;
end;
$$;
-- 선교지 대화방 알림: 같은 방의 다른 사람(나라 리더 · 선교사님, 리더가 없으면 관리자)에게
create or replace function public.notify_field_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare cc text;
begin
  select code into cc from public.countries where id = new.country_id;
  insert into public.notifications (user_id, kind, payload, link)
  select distinct u, 'field_msg', jsonb_build_object('country_id', new.country_id), '#/field/' || cc
    from (select user_id as u from public.country_leaders where country_id = new.country_id
          union select user_id from public.field_partners where country_id = new.country_id
          union select id from public.profiles where role = 'admin'
                and not exists (select 1 from public.country_leaders where country_id = new.country_id)) x
   where u is distinct from new.user_id;
  return new;
end;
$$;

-- 새 신청서가 들어오면 그 나라 리더에게
create or replace function public.notify_new_application()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select l.user_id, 'new_app', jsonb_build_object('country_id', new.country_id), '#/lead/' || new.id
    from public.country_leaders l where l.country_id = new.country_id and l.user_id <> new.user_id;
  return new;
end;
$$;

create or replace function public.notify_team_added()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select new.user_id, 'team_added', jsonb_build_object('team', t.name), '#/teams/' || new.team_id
    from public.teams t where t.id = new.team_id;
  return new;
end;
$$;

-- 합의 계획서 규칙: 선교지는 동의·수정 요청만 할 수 있고, 리더가 내용을 고치면 동의가 처음부터 다시 필요함
create or replace function public.guard_field_plan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  lead boolean := public.is_admin() or public.is_country_leader(old.country_id);
  skip  text[] := array['sent_at','field_agreed_at','field_agreed_by','field_agreed_via','field_agreed_note','field_comment','svm_agreed_at','svm_agreed_by','closed','updated_at'];
  fskip text[] := array['field_agreed_at','field_agreed_by','field_agreed_via','field_agreed_note','field_comment','updated_at'];
begin
  if new.country_id is distinct from old.country_id then raise exception 'country cannot change'; end if;
  new.updated_at := now();
  if not lead then
    if not public.is_field_partner(old.country_id) or old.sent_at is null then raise exception 'not allowed'; end if;
    if (to_jsonb(new) - fskip) is distinct from (to_jsonb(old) - fskip) then raise exception 'field partners can only agree or comment'; end if;
    if new.field_agreed_at is not null and (new.field_agreed_via is distinct from 'self' or new.field_agreed_by is distinct from auth.uid()) then
      raise exception 'bad agreement';
    end if;
    return new;
  end if;
  if (to_jsonb(new) - skip) is distinct from (to_jsonb(old) - skip) then   -- 내용이 바뀜 → 처음부터 다시
    new.sent_at := null; new.field_agreed_at := null; new.field_agreed_by := null; new.field_agreed_via := null; new.field_agreed_note := null;
    new.svm_agreed_at := null; new.svm_agreed_by := null; new.field_comment := null;
  end if;
  if new.field_agreed_via = 'leader' and new.field_agreed_at is not null and old.field_agreed_at is null then
    if coalesce(trim(new.field_agreed_note), '') = '' then raise exception 'PLAN_NOTE_REQUIRED'; end if;
    new.field_agreed_by := auth.uid();
    new.sent_at := coalesce(new.sent_at, now());
  end if;
  if new.svm_agreed_at is not null and old.svm_agreed_at is null then
    if new.field_agreed_at is null then raise exception 'PLAN_FIELD_FIRST'; end if;
    new.svm_agreed_by := auth.uid();
  end if;
  return new;
end;
$$;

-- 합의 계획서 알림: 보냄 → 선교사님 · 선교지 동의/수정 요청 → 리더와 관리자 · 확정 → 선교사님
create or replace function public.notify_plan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare pay jsonb := jsonb_build_object('country_id', new.country_id, 'title', new.title); lnk text := '#/plans/' || new.id;
begin
  if new.sent_at is not null and old.sent_at is null then
    insert into public.notifications (user_id, kind, payload, link)
    select user_id, 'plan_review', pay, lnk from public.field_partners where country_id = new.country_id and user_id is distinct from auth.uid();
  end if;
  if new.field_agreed_at is not null and old.field_agreed_at is null and new.field_agreed_via = 'self' then
    insert into public.notifications (user_id, kind, payload, link)
    select u, 'plan_field_agreed', pay, lnk from (select user_id as u from public.country_leaders where country_id = new.country_id
      union select id from public.profiles where role = 'admin') x where u is distinct from auth.uid();
  end if;
  if new.field_comment is not null and new.field_comment is distinct from old.field_comment then
    insert into public.notifications (user_id, kind, payload, link)
    select u, 'plan_changes', pay, lnk from (select user_id as u from public.country_leaders where country_id = new.country_id
      union select id from public.profiles where role = 'admin') x where u is distinct from auth.uid();
  end if;
  if new.svm_agreed_at is not null and old.svm_agreed_at is null then
    insert into public.notifications (user_id, kind, payload, link)
    select user_id, 'plan_agreed', pay, lnk from public.field_partners where country_id = new.country_id and user_id is distinct from auth.uid();
  end if;
  return new;
end;
$$;

-- 신청 승인 전에 합의된 계획서가 있어야 하는 설정(require_plan_to_approve)이 켜져 있으면 확인
create or replace function public.guard_application_plan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.plan_id is not null and not exists (select 1 from public.field_plans p where p.id = new.plan_id and p.country_id = new.country_id) then
    raise exception 'PLAN_COUNTRY';
  end if;
  if public.setting_bool('require_plan_to_approve')
     and old.status in ('submitted','rejected') and new.status not in ('submitted','rejected') then
    if new.plan_id is null or not exists (select 1 from public.field_plans p where p.id = new.plan_id and p.country_id = new.country_id
         and p.field_agreed_at is not null and p.svm_agreed_at is not null and not p.closed) then
      raise exception 'PLAN_REQUIRED';
    end if;
  end if;
  return new;
end;
$$;

-- 새 선교지 소식 → 그 나라를 품은 사람, 파송 준비·선교 중인 학생, 나라 리더에게 알림 (쓴 사람 제외)
create or replace function public.notify_field_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select u, 'field_update', jsonb_build_object('country_id', new.country_id), '#/feed/' || c.code
    from (select user_id as u from public.nation_pledges where country_id = new.country_id
          union select user_id from public.applications where country_id = new.country_id and status in ('approved','preparing','on_field')
          union select user_id from public.country_leaders where country_id = new.country_id) x
    join public.countries c on c.id = new.country_id
   where u is distinct from new.user_id;
  return new;
end;
$$;

-- 기도가 응답되면 함께 기도한 사람들에게 알림
create or replace function public.notify_prayer_answered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.answered and not coalesce(old.answered, false) then
    insert into public.notifications (user_id, kind, payload, link)
    select r.user_id, 'prayer_answered', jsonb_build_object('country_id', new.country_id), '#/feed'
      from public.prayer_reactions r where r.prayer_id = new.id and r.user_id <> new.user_id;
  end if;
  return new;
end;
$$;

-- 안부 체크인에서 '도움이 필요해요'를 누르면 맡은 리더와 관리자 모두에게 바로 알림
create or replace function public.notify_checkin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare a record;
begin
  if new.status <> 'need_help' then return new; end if;
  select id, country_id into a from public.applications where id = new.application_id;
  insert into public.notifications (user_id, kind, payload, link)
  select u, 'checkin_help', jsonb_build_object('country_id', a.country_id), '#/lead/' || a.id
    from (select user_id as u from public.country_leaders where country_id = a.country_id
          union select id from public.profiles where role = 'admin') x
   where u is distinct from new.user_id;
  return new;
end;
$$;

-- 매일 한 번 (pg_cron — sql/06_알림_예약.sql): 출발 준비 · 보험 · 안부 · 후기 알림을 만들어 둡니다.
-- 같은 알림은 reminder_log 로 한 번만 보냅니다. 앱·익명 사용자는 부를 수 없습니다.
create or replace function public.send_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  a record; d int; k int; b int; rk text; quiet int; base timestamptz; sent int := 0;
  leaders uuid[];
begin
  -- 1) 출발 전: 30 · 14 · 3 · 1일 전 (지금 구간 하나만, 한 번)
  for a in select id, user_id, country_id, start_date from public.applications
            where status in ('approved','preparing') and start_date is not null and start_date >= current_date loop
    d := a.start_date - current_date;
    b := null;
    foreach k in array array[1,3,14,30] loop
      if d <= k then b := k; exit; end if;
    end loop;
    if b is not null then
      rk := 'dep_' || b;
      if not exists (select 1 from public.reminder_log where application_id = a.id and reminder_log.key = rk) then
        insert into public.reminder_log (application_id, key) values (a.id, rk);
        insert into public.notifications (user_id, kind, payload, link)
        values (a.user_id, 'dep_remind', jsonb_build_object('days', d, 'country_id', a.country_id), '#/apps/' || a.id);
        sent := sent + 1;
      end if;
    end if;
    -- 보험 증서: 출발 10일 전·7일 전까지 안 냈거나 고쳐야 하면
    if d <= 10 and not exists (select 1 from public.application_insurance i where i.application_id = a.id and i.status in ('submitted','verified')) then
      rk := case when d <= 7 then 'ins_7' else 'ins_10' end;
      if not exists (select 1 from public.reminder_log where application_id = a.id and reminder_log.key = rk) then
        insert into public.reminder_log (application_id, key) values (a.id, rk);
        insert into public.notifications (user_id, kind, payload, link)
        values (a.user_id, 'ins_due', jsonb_build_object('days', d, 'country_id', a.country_id), '#/apps/' || a.id);
        sent := sent + 1;
      end if;
    end if;
  end loop;

  -- 2) 선교 중: 체크인이 3일 넘게 없으면 본인에게, 5일 넘게 없으면 리더(없으면 관리자)에게
  for a in select id, user_id, country_id, updated_at from public.applications where status = 'on_field' loop
    select max(created_at) into base from public.field_checkins where application_id = a.id;
    base := coalesce(base, (select max(changed_at) from public.application_status_history h where h.application_id = a.id and h.status = 'on_field'), a.updated_at);
    quiet := current_date - base::date;
    rk := 'ci_ask_' || current_date;
    if quiet >= 3 and quiet % 3 = 0 and not exists (select 1 from public.reminder_log where application_id = a.id and reminder_log.key = rk) then
      insert into public.reminder_log (application_id, key) values (a.id, rk);
      insert into public.notifications (user_id, kind, payload, link)
      values (a.user_id, 'checkin_ask', jsonb_build_object('country_id', a.country_id), '#/apps/' || a.id);
      sent := sent + 1;
    end if;
    rk := 'ci_miss_' || current_date;
    if quiet >= 5 and (quiet = 5 or quiet % 7 = 0) and not exists (select 1 from public.reminder_log where application_id = a.id and reminder_log.key = rk) then
      insert into public.reminder_log (application_id, key) values (a.id, rk);
      select coalesce(array_agg(user_id), '{}') into leaders from public.country_leaders where country_id = a.country_id;
      insert into public.notifications (user_id, kind, payload, link)
      select u, 'checkin_miss', jsonb_build_object('country_id', a.country_id, 'days', quiet), '#/lead/' || a.id
        from unnest(case when array_length(leaders, 1) > 0 then leaders
                         else (select coalesce(array_agg(id), '{}') from public.profiles where role = 'admin') end) u;
      sent := sent + 1;
    end if;
  end loop;

  -- 3) 돌아온 지 7일째 후기를 아직 안 나눴으면 한 번 더 초대
  for a in select ap.id, ap.user_id, ap.country_id from public.applications ap
            where ap.status = 'returned'
              and exists (select 1 from public.application_status_history h where h.application_id = ap.id and h.status = 'returned'
                           and h.changed_at <= now() - interval '7 days' and h.changed_at > now() - interval '30 days')
              and not exists (select 1 from public.testimonies t where t.user_id = ap.user_id
                               and t.created_at >= (select max(changed_at) from public.application_status_history h where h.application_id = ap.id and h.status = 'returned')) loop
    if not exists (select 1 from public.reminder_log where application_id = a.id and reminder_log.key = 'testi_7') then
      insert into public.reminder_log (application_id, key) values (a.id, 'testi_7');
      insert into public.notifications (user_id, kind, payload, link)
      values (a.user_id, 'returned_testi', jsonb_build_object('country_id', a.country_id), '#/apps/' || a.id);
      sent := sent + 1;
    end if;
  end loop;
  return sent;
end;
$$;
revoke all on function public.send_reminders() from public, anon, authenticated;

do $$
declare tb text;
begin
  foreach tb in array array['applications','application_extensions','application_insurance','graduation_requests','testimonies','support_stories','course_feedback'] loop
    execute format('drop trigger if exists notify_changes on public.%I', tb);
    execute format('create trigger notify_changes after update on public.%I for each row execute function public.notify_changes()', tb);
  end loop;
end $$;
drop trigger if exists notify_report on public.content_reports;
create trigger notify_report after insert on public.content_reports
  for each row execute function public.notify_report();
drop trigger if exists notify_app_message on public.application_messages;
create trigger notify_app_message after insert on public.application_messages
  for each row execute function public.notify_app_message();
drop trigger if exists notify_field_message on public.field_messages;
create trigger notify_field_message after insert on public.field_messages
  for each row execute function public.notify_field_message();
drop trigger if exists guard_field_plan on public.field_plans;
create trigger guard_field_plan before update on public.field_plans for each row execute function public.guard_field_plan();
drop trigger if exists notify_plan on public.field_plans;
create trigger notify_plan after update on public.field_plans for each row execute function public.notify_plan();
drop trigger if exists guard_application_plan on public.applications;
create trigger guard_application_plan before update on public.applications for each row execute function public.guard_application_plan();
drop trigger if exists notify_field_update on public.field_updates;
create trigger notify_field_update after insert on public.field_updates
  for each row execute function public.notify_field_update();
drop trigger if exists notify_prayer_answered on public.prayers;
create trigger notify_prayer_answered after update on public.prayers
  for each row execute function public.notify_prayer_answered();
drop trigger if exists notify_checkin on public.field_checkins;
create trigger notify_checkin after insert on public.field_checkins
  for each row execute function public.notify_checkin();
drop trigger if exists notify_new_application on public.applications;
create trigger notify_new_application after insert on public.applications
  for each row execute function public.notify_new_application();
drop trigger if exists notify_team_added on public.team_members;
create trigger notify_team_added after insert on public.team_members
  for each row execute function public.notify_team_added();

-- =====================================================================
-- Storage 버킷 & 정책
--   country-photos : 국가 사진 (관리자 업로드, 공개)
--   audio          : 복음 메시지 음성 (관리자 업로드, 공개)
--   testimony-photos : 후기 사진 (회원은 본인 폴더 {user_id}/... 에만 업로드)
--   insurance-docs   : 여행자 보험 증서 (비공개 — 본인 폴더만 올리고 보기, 관리자는 모두 보기)
-- =====================================================================
do $$ begin
  if exists (select 1 from information_schema.tables where table_schema = 'storage' and table_name = 'buckets') then
    insert into storage.buckets (id, name, public) values
      ('country-photos', 'country-photos', true),
      ('audio', 'audio', true),
      ('testimony-photos', 'testimony-photos', true),
      ('insurance-docs', 'insurance-docs', false)
    on conflict (id) do nothing;
    update storage.buckets set public = false where id = 'insurance-docs';

    drop policy if exists "svm: public read"          on storage.objects;
    drop policy if exists "svm: admin upload"         on storage.objects;
    drop policy if exists "svm: admin modify"         on storage.objects;
    drop policy if exists "svm: admin remove"         on storage.objects;
    drop policy if exists "svm: member testimony upload" on storage.objects;
    drop policy if exists "svm: member testimony remove" on storage.objects;
    drop policy if exists "svm: partner photo upload" on storage.objects;
    drop policy if exists "svm: partner photo remove" on storage.objects;
    drop policy if exists "svm: insurance own upload" on storage.objects;
    drop policy if exists "svm: insurance own or admin read" on storage.objects;
    drop policy if exists "svm: insurance own remove" on storage.objects;

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
    create policy "svm: partner photo upload" on storage.objects for insert to authenticated
      with check (bucket_id = 'country-photos' and exists (select 1 from public.countries c
        where lower(c.code) = (storage.foldername(name))[1] and public.can_edit_country(c.id)));
    create policy "svm: partner photo remove" on storage.objects for delete to authenticated
      using (bucket_id = 'country-photos' and exists (select 1 from public.countries c
        where lower(c.code) = (storage.foldername(name))[1] and public.can_edit_country(c.id)));
    create policy "svm: insurance own upload" on storage.objects for insert to authenticated
      with check (bucket_id = 'insurance-docs' and (storage.foldername(name))[1] = auth.uid()::text);
    create policy "svm: insurance own or admin read" on storage.objects for select to authenticated
      using (bucket_id = 'insurance-docs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()
        or exists (select 1 from public.application_insurance i where i.file_path = name and public.can_manage_application(i.application_id))));
    create policy "svm: insurance own remove" on storage.objects for delete to authenticated
      using (bucket_id = 'insurance-docs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
  end if;
end $$;
