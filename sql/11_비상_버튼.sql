-- =====================================================================
-- 비상 버튼: 도움 요청에 리더가 "확인했어요"를 남기고, 학생에게 알림이 갑니다.
--   · 출국 직전·이동 중(승인/준비 단계)에도 도움 요청을 보낼 수 있게 허용
--   · 리더·관리자는 확인 표시(acked_*)만 고칠 수 있음 (다른 칸은 못 바꿈)
--   여러 번 실행해도 안전합니다.
-- =====================================================================
alter table public.field_checkins add column if not exists acked_at timestamptz;
alter table public.field_checkins add column if not exists acked_by uuid references public.profiles(id) on delete set null;
alter table public.field_checkins add column if not exists ack_note text check (ack_note is null or char_length(ack_note) <= 500);

drop policy if exists "checkins: self send" on public.field_checkins;
create policy "checkins: self send" on public.field_checkins for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.applications a where a.id = application_id and a.user_id = auth.uid()
              and (a.status = 'on_field' or (field_checkins.status = 'need_help' and a.status in ('approved','preparing')))));

drop policy if exists "checkins: manager ack" on public.field_checkins;
create policy "checkins: manager ack" on public.field_checkins for update
  using (public.can_manage_application(application_id)) with check (public.can_manage_application(application_id));

-- 확인 표시 외의 칸은 바꿀 수 없게
create or replace function public.guard_checkin_ack()
returns trigger
language plpgsql
as $$
begin
  if new.application_id is distinct from old.application_id or new.user_id is distinct from old.user_id
     or new.status is distinct from old.status or new.note is distinct from old.note
     or new.created_at is distinct from old.created_at then
    raise exception 'only acknowledgement fields can be changed';
  end if;
  if new.acked_at is not null and new.acked_by is null then new.acked_by := auth.uid(); end if;
  return new;
end;
$$;
drop trigger if exists guard_checkin_ack on public.field_checkins;
create trigger guard_checkin_ack before update on public.field_checkins
  for each row execute function public.guard_checkin_ack();

-- 리더가 확인하면 학생에게 알림
create or replace function public.notify_checkin_ack()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.acked_at is null and new.acked_at is not null then
    insert into public.notifications (user_id, kind, payload, link)
    values (new.user_id, 'checkin_ack', jsonb_build_object('application_id', new.application_id), '#/sos/' || new.application_id);
  end if;
  return new;
end;
$$;
drop trigger if exists notify_checkin_ack on public.field_checkins;
create trigger notify_checkin_ack after update on public.field_checkins
  for each row execute function public.notify_checkin_ack();
