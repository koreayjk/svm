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
--   extra_sections: 관리자가 추가하는 항목 [{ "title_en":..,"title_ko":..,"body_en":..,"body_ko":.. }]
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
  extra_sections jsonb not null default '[]'::jsonb,
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
  changed_by      uuid references public.profiles(id),
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
  source_text    text not null,
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
-- ⑤ 오프라인 연결 — 주간 미션 게더링
-- ---------------------------------------------------------------------
create table if not exists public.gatherings (
  id             bigint generated always as identity primary key,
  date           date not null unique,
  start_time     time not null default '14:00',
  end_time       time not null default '16:00',
  location       text,
  title          text,
  sermon_notes   text,
  sharing_notes  text
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
-- 앱 설정 (require_graduation_to_apply, sensitive_photo_block 등)
-- ---------------------------------------------------------------------
create table if not exists public.app_settings (
  key    text primary key,
  value  jsonb not null
);

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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
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
