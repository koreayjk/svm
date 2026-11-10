-- 18. 나라 사진 순서 바꾸기·대표 사진 고르기
-- 나라 사진의 "대표"는 맨 앞 사진입니다 (sort_order 가 가장 작은 사진). 순서를 바꾸면 대표 사진도 바뀝니다.
-- 지금까지 사진은 관리자만 고칠 수 있고 나라 리더·선교사님은 올리기·지우기만 됐습니다.
-- 이제 자기 나라 사진의 순서(sort_order)는 나라 리더·선교사님도 바꿀 수 있습니다. (사진 주소·나라는 못 바꿈)
-- 영상(country_videos)은 이미 나라 담당자가 모두 고칠 수 있어서 따로 바꿀 것이 없습니다.
-- 여러 번 실행해도 안전합니다.

drop policy if exists "photos: partner update" on public.country_photos;
create policy "photos: partner update" on public.country_photos for update
  using (public.can_edit_country(country_id)) with check (public.can_edit_country(country_id));

-- 관리자가 아니면 순서·설명만 바꿀 수 있다 (다른 나라로 옮기거나 주소를 바꾸는 것은 막음)
create or replace function public.guard_photo_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then return new; end if;
  if new.country_id is distinct from old.country_id or new.url is distinct from old.url
     or new.uploaded_by is distinct from old.uploaded_by then
    raise exception 'photo_locked';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_photo_update on public.country_photos;
create trigger guard_photo_update before update on public.country_photos
  for each row execute function public.guard_photo_update();
