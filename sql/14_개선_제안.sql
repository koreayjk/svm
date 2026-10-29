-- =====================================================================
-- 개선 제안 게시판 (임시): 써 보고 불편한 점·아이디어를 사진과 함께 올리고, 서로 댓글을 답니다.
--   여러 번 실행해도 안전합니다. 사진은 기존 testimony-photos 저장소(본인 폴더)를 씁니다.
-- =====================================================================
create table if not exists public.feedback_posts (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        text not null default 'idea' check (kind in ('idea','problem')),
  body        text not null check (char_length(body) between 1 and 2000),
  photos      text[] not null default '{}' check (coalesce(array_length(photos, 1), 0) <= 3),
  status      text not null default 'open' check (status in ('open','planned','done')),
  created_at  timestamptz not null default now()
);
create index if not exists feedback_posts_created_idx on public.feedback_posts(created_at desc);

create table if not exists public.feedback_comments (
  id          bigint generated always as identity primary key,
  post_id     bigint not null references public.feedback_posts(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 1000),
  created_at  timestamptz not null default now()
);
create index if not exists feedback_comments_post_idx on public.feedback_comments(post_id, created_at);

alter table public.feedback_posts enable row level security;
alter table public.feedback_comments enable row level security;
drop policy if exists "feedback: read" on public.feedback_posts;
drop policy if exists "feedback: post" on public.feedback_posts;
drop policy if exists "feedback: own delete" on public.feedback_posts;
drop policy if exists "feedback: admin status" on public.feedback_posts;
drop policy if exists "fb comments: read" on public.feedback_comments;
drop policy if exists "fb comments: post" on public.feedback_comments;
drop policy if exists "fb comments: own delete" on public.feedback_comments;
create policy "feedback: read"         on public.feedback_posts for select to authenticated using (true);
create policy "feedback: post"         on public.feedback_posts for insert to authenticated with check (user_id = auth.uid() and status = 'open');
create policy "feedback: own delete"   on public.feedback_posts for delete to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "feedback: admin status" on public.feedback_posts for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "fb comments: read"       on public.feedback_comments for select to authenticated using (true);
create policy "fb comments: post"       on public.feedback_comments for insert to authenticated with check (user_id = auth.uid());
create policy "fb comments: own delete" on public.feedback_comments for delete to authenticated using (user_id = auth.uid() or public.is_admin());

-- 신고 종류에 개선 제안 글·댓글 추가
do $$ declare c text; begin
  select conname into c from pg_constraint where conrelid = 'public.content_reports'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%target_kind%';
  if c is not null then execute format('alter table public.content_reports drop constraint %I', c); end if;
  alter table public.content_reports add constraint content_reports_target_kind_check
    check (target_kind in ('message','prayer','testimony','team_post','user','feedback','feedback_comment'));
end $$;

-- 알림: 새 글 → 관리자 · 댓글 → 글쓴이(와 앞서 댓글 단 사람) · 상태 변경 → 글쓴이
create or replace function public.notify_feedback_post()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, kind, payload, link)
  select id, 'fb_new', '{}'::jsonb, '#/ideas/' || new.id from public.profiles where role = 'admin' and id <> new.user_id;
  return new;
end;
$$;
drop trigger if exists notify_feedback_post on public.feedback_posts;
create trigger notify_feedback_post after insert on public.feedback_posts for each row execute function public.notify_feedback_post();

create or replace function public.notify_feedback_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare owner uuid;
begin
  select user_id into owner from public.feedback_posts where id = new.post_id;
  insert into public.notifications (user_id, kind, payload, link)
  select distinct u, 'fb_comment', '{}'::jsonb, '#/ideas/' || new.post_id
    from (select owner as u union select user_id from public.feedback_comments where post_id = new.post_id) x
   where u is not null and u <> new.user_id;
  return new;
end;
$$;
drop trigger if exists notify_feedback_comment on public.feedback_comments;
create trigger notify_feedback_comment after insert on public.feedback_comments for each row execute function public.notify_feedback_comment();

create or replace function public.notify_feedback_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    insert into public.notifications (user_id, kind, payload, link)
    values (new.user_id, 'fb_status', jsonb_build_object('status', new.status), '#/ideas/' || new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists notify_feedback_status on public.feedback_posts;
create trigger notify_feedback_status after update on public.feedback_posts for each row execute function public.notify_feedback_status();
