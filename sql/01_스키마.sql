-- =====================================================================
-- SVM App — 01_스키마.sql
-- Supabase 대시보드 > SQL Editor 에서 순서대로 실행하세요.
--   01_스키마.sql → 02_RLS.sql → 03_국가_시드.sql → (회원가입 후) 04_관리자_지정.sql
-- 여러 번 실행해도 안전하도록 IF NOT EXISTS 를 사용합니다.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 회원 프로필 (auth.users 와 1:1)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text,
  email       text,
  phone       text,
  school      text,
  role        text not null default 'member' check (role in ('member','graduate','admin')),
  lang        text not null default 'en' check (lang in ('en','ko')),
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ① 나라별 현지 정보
--   *_ko 컬럼: 한국어 버전 (비어 있으면 영어 컬럼을 표시)
--   extra_provided: "선교지에서 제공" 블록에 국가별로 덧붙일 문구 (공통 항목은 app_settings.provided_items)
--   extra_sections: 관리자가 추가하는 항목 [{ "title_en":..,"title_ko":..,"body_en":..,"body_ko":.. }]
--   booth_meta: 2단계 메타버스 부스용 예비 컬럼 (지금은 비워 둠)
-- ---------------------------------------------------------------------
create table if not exists public.countries (
  id            bigint generated always as identity primary key,
  code          text not null unique,               -- ISO 2자리 (KR, PH ...)
  name_en       text not null,
  name_ko       text not null,
  is_sensitive  boolean not null default false,
  intro         text, intro_ko       text,
  ministry      text, ministry_ko    text,
  daily_life    text, daily_life_ko  text,
  language      text, language_ko    text,
  housing       text, housing_ko     text,
  extra_provided text, extra_provided_ko text,
  extra_sections jsonb not null default '[]'::jsonb,
  booth_meta    jsonb not null default '{}'::jsonb,
  sort_order    int not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

create table if not exists public.country_photos (
  id          bigint generated always as identity primary key,
  country_id  bigint not null references public.countries(id) on delete cascade,
  url         text not null,
  caption     text,
  sort_order  int not null default 0
);

-- 내 나라에 이름 쓰기 (Sign Your Nation) — 신청과 별개의 가벼운 헌신 표시
create table if not exists public.nation_pledges (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  country_id  bigint not null references public.countries(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, country_id)
);
create index if not exists nation_pledges_country_idx on public.nation_pledges(country_id);

-- ---------------------------------------------------------------------
-- ② 소통 — 나라별 방
-- ---------------------------------------------------------------------
create table if not exists public.room_members (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  country_id    bigint not null references public.countries(id) on delete cascade,
  joined_at     timestamptz not null default now(),
  last_read_at  timestamptz not null default now(),   -- 안 읽은 메시지 계산용
  primary key (user_id, country_id)
);

create table if not exists public.messages (
  id          bigint generated always as identity primary key,
  country_id  bigint not null references public.countries(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 4000),
  created_at  timestamptz not null default now(),
  deleted     boolean not null default false
);
create index if not exists messages_country_created_idx on public.messages(country_id, created_at desc);

-- ---------------------------------------------------------------------
-- ⑦ 신청 & 매칭
-- ---------------------------------------------------------------------
create table if not exists public.applications (
  id               bigint generated always as identity primary key,
  user_id          uuid not null references public.profiles(id) on delete cascade,
  country_id       bigint not null references public.countries(id),
  track            text not null default 'short' check (track in ('short','mid','long')),  -- 단기 Into the World / 중기 1–2년 / 장기
  start_date       date,
  duration_text    text,
  expected_return  date,
  contact          text,
  motivation       text,
  status           text not null default 'submitted'
                   check (status in ('submitted','approved','rejected','preparing','on_field','returned')),
  admin_note       text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists applications_user_idx on public.applications(user_id);
create index if not exists applications_country_status_idx on public.applications(country_id, status);

-- 상태 변경 이력 (회원 타임라인 표시용)
create table if not exists public.application_status_history (
  id              bigint generated always as identity primary key,
  application_id  bigint not null references public.applications(id) on delete cascade,
  status          text not null,
  changed_by      uuid references public.profiles(id) on delete set null,   -- 처리한 관리자 (탈퇴해도 이력은 남김)
  changed_at      timestamptz not null default now()
);

create table if not exists public.application_extensions (
  id               bigint generated always as identity primary key,
  application_id   bigint not null references public.applications(id) on delete cascade,
  new_return_date  date not null,
  reason           text,
  status           text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at       timestamptz not null default now(),
  reviewed_at      timestamptz
);

-- ---------------------------------------------------------------------
-- ③ 교육 — A. 언어 훈련
-- ---------------------------------------------------------------------
create table if not exists public.gospel_messages (
  id          bigint generated always as identity primary key,
  title       text not null,
  base_text   text,
  sort_order  int not null default 0,
  is_active   boolean not null default true
);

create table if not exists public.gospel_sentences (
  id             bigint generated always as identity primary key,
  message_id     bigint not null references public.gospel_messages(id) on delete cascade,
  country_id     bigint not null references public.countries(id) on delete cascade,
  seq            int not null default 0,
  source_text    text not null,          -- 뜻 (영어)
  source_ko      text,                   -- 뜻 (한국어)
  local_text     text,
  pronunciation  text,
  audio_url      text
);
create index if not exists gospel_sentences_msg_country_idx on public.gospel_sentences(message_id, country_id, seq);

create table if not exists public.language_progress (
  user_id         uuid not null references public.profiles(id) on delete cascade,
  sentence_id     bigint not null references public.gospel_sentences(id) on delete cascade,
  repeat_count    int not null default 0,
  correct_count   int not null default 0,
  wrong_count     int not null default 0,
  mastery         smallint not null default 0 check (mastery between 0 and 3),
  last_practiced  timestamptz,
  primary key (user_id, sentence_id)
);

-- 연속 학습일 계산용 (하루 1행)
create table if not exists public.practice_days (
  user_id   uuid not null references public.profiles(id) on delete cascade,
  day       date not null,
  primary key (user_id, day)
);

-- ---------------------------------------------------------------------
-- ③ 교육 — B. 선교 교육 커리큘럼 / C. 수료
-- ---------------------------------------------------------------------
create table if not exists public.courses (
  id           bigint generated always as identity primary key,
  title_en     text not null,
  title_ko     text,
  video_url    text,
  description  text,
  description_ko text,
  sort_order   int not null default 0,
  required     boolean not null default true
);

create table if not exists public.course_feedback (
  id             bigint generated always as identity primary key,
  user_id        uuid not null references public.profiles(id) on delete cascade,
  course_id      bigint not null references public.courses(id) on delete cascade,
  feedback       text not null,
  admin_comment  text,
  completed_at   timestamptz not null default now(),
  unique (user_id, course_id)
);

create table if not exists public.graduation_requests (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);

-- ---------------------------------------------------------------------
-- ④ 팀 & 그룹 프로젝트 (팀 구성 방식은 추후 결정 — 일반적 구조)
-- ---------------------------------------------------------------------
create table if not exists public.teams (
  id           bigint generated always as identity primary key,
  name         text not null,
  country_id   bigint references public.countries(id) on delete set null,
  description  text,
  created_at   timestamptz not null default now()
);

create table if not exists public.team_members (
  team_id  bigint not null references public.teams(id) on delete cascade,
  user_id  uuid not null references public.profiles(id) on delete cascade,
  role     text not null default 'member',   -- leader / member 등 (자유 텍스트)
  primary key (team_id, user_id)
);

create table if not exists public.team_tasks (
  id          bigint generated always as identity primary key,
  team_id     bigint not null references public.teams(id) on delete cascade,
  title       text not null,
  assignee    uuid references public.profiles(id) on delete set null,
  status      text not null default 'todo' check (status in ('todo','doing','done')),
  due_date    date,
  created_at  timestamptz not null default now()
);

create table if not exists public.team_posts (
  id          bigint generated always as identity primary key,
  team_id     bigint not null references public.teams(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  body        text not null,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ⑤ 오프라인 연결 — 주간 모임
--   sunday: 주일 미션 게더링 (오후 2–4시, 교회)
--   friday: 현재 쓰지 않음 (금요 모임 없음, 나중을 위해 값만 허용)
-- ---------------------------------------------------------------------
create table if not exists public.gatherings (
  id             bigint generated always as identity primary key,
  type           text not null default 'sunday' check (type in ('sunday','friday')),
  date           date not null,
  start_time     time not null default '14:00',
  end_time       time not null default '16:00',
  location       text,
  title          text,
  sermon_notes   text,
  sharing_notes  text,
  unique (date, type)
);

create table if not exists public.attendance (
  gathering_id  bigint not null references public.gatherings(id) on delete cascade,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  checked_at    timestamptz not null default now(),
  primary key (gathering_id, user_id)
);

-- ---------------------------------------------------------------------
-- ⑥ 선교 후기 & 간증 (승인제)
-- ---------------------------------------------------------------------
create table if not exists public.testimonies (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  country_id  bigint references public.countries(id) on delete set null,
  prayer_id   bigint,   -- 응답된 기도에서 연결된 경우 (FK 는 prayers 생성 후 추가)
  title       text not null,
  body        text not null,
  photos      text[] not null default '{}',
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  featured    boolean not null default false,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ⑧ 기도 제목 나눔
-- ---------------------------------------------------------------------
create table if not exists public.prayers (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  country_id  bigint references public.countries(id) on delete cascade,
  body        text not null,
  answered    boolean not null default false,
  created_at  timestamptz not null default now()
);

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'testimonies_prayer_id_fkey') then
    alter table public.testimonies
      add constraint testimonies_prayer_id_fkey foreign key (prayer_id) references public.prayers(id) on delete set null;
  end if;
end $$;

create table if not exists public.prayer_reactions (
  prayer_id   bigint not null references public.prayers(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (prayer_id, user_id)          -- 1인 1회
);

-- ---------------------------------------------------------------------
-- ⑨ 후원 & 준비물 안내
-- ---------------------------------------------------------------------
create table if not exists public.checklist_items (
  id          bigint generated always as identity primary key,
  country_id  bigint references public.countries(id) on delete cascade,  -- null = 모든 국가 공통
  label_en    text not null,
  label_ko    text,
  sort_order  int not null default 0
);

create table if not exists public.checklist_progress (
  user_id  uuid not null references public.profiles(id) on delete cascade,
  item_id  bigint not null references public.checklist_items(id) on delete cascade,
  checked  boolean not null default false,
  primary key (user_id, item_id)
);

create table if not exists public.support_stories (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  title       text not null,
  story       text not null,
  link_url    text,
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 특별 이벤트 (미션 컨퍼런스, 발족식, 수련회 등 — 매주 모임(gatherings)과 별개)
--   is_featured: 홈 맨 위 큰 배너로 노출 (여러 개면 가장 가까운 것)
--   all_day: 시간 미정/종일 이벤트는 날짜만 표시
-- ---------------------------------------------------------------------
create table if not exists public.events (
  id              bigint generated always as identity primary key,
  title_en        text not null,
  title_ko        text,
  subtitle_en     text,
  subtitle_ko     text,
  description_en  text,
  description_ko  text,
  starts_at       timestamptz not null,
  ends_at         timestamptz,
  all_day         boolean not null default false,
  location        text,
  image_url       text,
  link_url        text,          -- 외부 등록/안내 페이지 (선택)
  is_featured     boolean not null default false,
  is_published    boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists events_starts_idx on public.events(starts_at);

-- ---------------------------------------------------------------------
-- 앱 설정 (require_graduation_to_apply, sensitive_photo_block,
--          provided_items, prepare_items, mission_seasons 등)
-- ---------------------------------------------------------------------
create table if not exists public.app_settings (
  key    text primary key,
  value  jsonb not null
);

-- ---------------------------------------------------------------------
-- 컨퍼런스 등록 (홈페이지 /conference/ 의 등록 폼 — 로그인 없이 제출)
-- 공개(anon)는 넣기만 가능, 읽기는 관리자만. 같은 이메일은 한 번만.
-- ---------------------------------------------------------------------
create table if not exists public.conference_registrations (
  id          bigint generated always as identity primary key,
  event_key   text not null default 'mc2026',
  full_name   text not null check (char_length(full_name) between 1 and 120),
  email       text not null check (char_length(email) between 3 and 200 and email like '%_@_%'),
  phone       text check (phone is null or char_length(phone) <= 40),
  role        text not null default 'other'
              check (role in ('student','young_adult','youth','leader','volunteer','other')),
  lang        text not null default 'en' check (lang in ('en','ko')),
  created_at  timestamptz not null default now()
);
create unique index if not exists conference_registrations_email_uq
  on public.conference_registrations (event_key, lower(email));

-- =====================================================================
-- v1 → v2 업그레이드 (v1 SQL 을 이미 실행한 DB 용 — 새 DB 에서는 아무 일도 하지 않음)
-- =====================================================================
alter table public.countries    add column if not exists extra_provided    text;
alter table public.countries    add column if not exists extra_provided_ko text;
alter table public.countries    add column if not exists booth_meta        jsonb not null default '{}'::jsonb;
alter table public.applications add column if not exists track             text not null default 'short';
alter table public.gatherings   add column if not exists type              text not null default 'sunday';
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'applications_track_check') then
    alter table public.applications add constraint applications_track_check check (track in ('short','mid','long'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'gatherings_type_check') then
    alter table public.gatherings add constraint gatherings_type_check check (type in ('sunday','friday'));
  end if;
  if exists (select 1 from pg_constraint where conname = 'gatherings_date_key') then
    alter table public.gatherings drop constraint gatherings_date_key;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'gatherings_date_type_key') then
    alter table public.gatherings add constraint gatherings_date_type_key unique (date, type);
  end if;
end $$;

-- =====================================================================
-- 공통 트리거
-- =====================================================================

-- 신규 가입 시 profiles 행 자동 생성 (회원가입 폼의 metadata 사용)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, phone, school, lang)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data->>'name', ''),
    nullif(new.raw_user_meta_data->>'phone', ''),
    nullif(new.raw_user_meta_data->>'school', ''),
    coalesce(nullif(new.raw_user_meta_data->>'lang', ''), 'en')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists svm_on_auth_user_created on auth.users;
create trigger svm_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- applications.updated_at 자동 갱신 + 상태 이력 기록
create or replace function public.applications_touch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' then
    new.updated_at := now();
    if new.status is distinct from old.status then
      insert into public.application_status_history (application_id, status, changed_by)
      values (new.id, new.status, auth.uid());
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.applications_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.application_status_history (application_id, status, changed_by)
  values (new.id, new.status, auth.uid());
  return new;
end;
$$;

drop trigger if exists applications_touch on public.applications;
create trigger applications_touch
  before update on public.applications
  for each row execute function public.applications_touch();

drop trigger if exists applications_after_insert on public.applications;
create trigger applications_after_insert
  after insert on public.applications
  for each row execute function public.applications_after_insert();

-- 연장 승인 시 신청서의 귀국 예정일 갱신 (이력은 application_extensions 에 보관)
create or replace function public.extension_apply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update public.applications set expected_return = new.new_return_date where id = new.application_id;
  end if;
  if new.status is distinct from old.status and new.status <> 'pending' then
    new.reviewed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists extension_apply on public.application_extensions;
create trigger extension_apply
  before update on public.application_extensions
  for each row execute function public.extension_apply();

-- 수료 승인 시 graduate 등급 부여
create or replace function public.graduation_apply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update public.profiles set role = 'graduate' where id = new.user_id and role = 'member';
  end if;
  if new.status is distinct from old.status and new.status <> 'pending' then
    new.reviewed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists graduation_apply on public.graduation_requests;
create trigger graduation_apply
  before update on public.graduation_requests
  for each row execute function public.graduation_apply();

-- 회원 삭제 시 신청 이력의 changed_by 는 비워 둠 (예전 버전은 삭제가 막혔음)
alter table public.application_status_history drop constraint if exists application_status_history_changed_by_fkey;
alter table public.application_status_history
  add constraint application_status_history_changed_by_fkey foreign key (changed_by) references public.profiles(id) on delete set null;

-- 3단계: 복음 메시지 뜻(한국어) · 강의 설명(한국어)
alter table public.gospel_sentences add column if not exists source_ko      text;
alter table public.courses          add column if not exists description_ko text;

-- ---------------------------------------------------------------------
-- 앱 안 알림 (신청·연장·수료·후기 결과, 리더 답글, 팀 추가) — DB 트리거가 만듦
-- ---------------------------------------------------------------------
create table if not exists public.notifications (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        text not null,
  payload     jsonb not null default '{}'::jsonb,
  link        text,
  created_at  timestamptz not null default now(),
  read_at     timestamptz
);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);

-- 신청서 내부 메모 (관리자만 — 신청자에게 보이지 않음)
create table if not exists public.application_notes (
  application_id  bigint primary key references public.applications(id) on delete cascade,
  note            text,
  updated_at      timestamptz not null default now()
);

-- 여행자 보험 (Into the World 참가자 필수 · 출발 7일 전까지 증서 제출)
--   증서 파일은 비공개 버킷 insurance-docs/{user_id}/... 에 저장, 본인과 관리자만 열람
create table if not exists public.application_insurance (
  application_id     bigint primary key references public.applications(id) on delete cascade,
  user_id            uuid not null references public.profiles(id) on delete cascade,
  provider           text not null,
  policy_number      text,
  coverage_start     date,
  coverage_end       date,
  covers_medical     boolean not null default false,   -- 해외 의료비 $50,000–100,000+
  covers_evacuation  boolean not null default false,   -- 응급 후송 $250,000+
  covers_volunteer   boolean not null default false,   -- 봉사·선교 활동 중 사고 보장
  file_path          text not null,
  status             text not null default 'submitted' check (status in ('submitted','verified','needs_fix')),
  admin_note         text,
  submitted_at       timestamptz not null default now(),
  reviewed_at        timestamptz
);
create index if not exists application_insurance_user_idx on public.application_insurance(user_id);

-- 신고 · 차단 (앱스토어·구글플레이 사용자 생성 콘텐츠 정책)
--   신고는 관리자만 보고 처리, 차단은 본인 화면에서 그 사람의 글을 숨김
create table if not exists public.content_reports (
  id              bigint generated always as identity primary key,
  reporter_id     uuid references public.profiles(id) on delete set null,
  target_kind     text not null check (target_kind in ('message','prayer','testimony','team_post','user')),
  target_id       bigint,
  target_user_id  uuid references public.profiles(id) on delete set null,   -- 신고된 사람이 탈퇴해도 기록은 남김
  reason          text not null check (reason in ('spam','harassment','inappropriate','safety','other')),
  detail          text,
  excerpt         text,                                  -- 신고 당시 내용 일부 (지워져도 확인 가능)
  status          text not null default 'open' check (status in ('open','resolved','dismissed')),
  created_at      timestamptz not null default now(),
  resolved_at     timestamptz
);
create index if not exists content_reports_status_idx on public.content_reports(status, created_at desc);

create table if not exists public.user_blocks (
  blocker_id  uuid not null references public.profiles(id) on delete cascade,
  blocked_id  uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

-- 스토어 앱 푸시 알림을 받을 기기 (Firebase Cloud Messaging 토큰)
create table if not exists public.device_tokens (
  token       text primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  platform    text check (platform in ('ios','android','web')),
  lang        text,
  updated_at  timestamptz not null default now()
);
create index if not exists device_tokens_user_idx on public.device_tokens(user_id);
