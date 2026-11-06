-- 17. 나이대 (선택 항목)
-- 가입이나 마이 탭에서 나이대를 고르면 관리자 통계에서 "나이대별 인원"을 볼 수 있습니다.
-- 정확한 생년월일은 받지 않고, 구간만 받습니다. 비워 두어도 됩니다.
-- 여러 번 실행해도 안전합니다.

alter table public.profiles add column if not exists age_range text;

alter table public.profiles drop constraint if exists profiles_age_range_check;
alter table public.profiles add constraint profiles_age_range_check
  check (age_range is null or age_range in ('u18', 'a18_22', 'a23_29', 'a30_39', 'a40_49', 'a50'));

-- 가입할 때 보낸 나이대도 함께 저장 (허용된 값만)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ar text := nullif(new.raw_user_meta_data->>'age_range', '');
begin
  if ar is not null and ar not in ('u18', 'a18_22', 'a23_29', 'a30_39', 'a40_49', 'a50') then ar := null; end if;
  insert into public.profiles (id, email, name, phone, school, lang, age_range)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data->>'name', ''),
    nullif(new.raw_user_meta_data->>'phone', ''),
    nullif(new.raw_user_meta_data->>'school', ''),
    coalesce(nullif(new.raw_user_meta_data->>'lang', ''), 'en'),
    ar
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
