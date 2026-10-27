-- =====================================================================
-- 나라 리더(SVM 담당자)도 자기 나라의 사진 · 영상 · 소식 · 소개를 올리고 고칠 수 있게
--   (전에는 선교사님과 관리자만 가능했습니다). 여러 번 실행해도 안전합니다.
-- =====================================================================
create or replace function public.can_edit_country(cid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select public.is_admin() or public.is_field_partner(cid) or public.is_country_leader(cid); $$;

drop policy if exists "countries: partner edit" on public.countries;
create policy "countries: partner edit" on public.countries for update using (public.can_edit_country(id)) with check (public.can_edit_country(id));

drop policy if exists "photos: partner add" on public.country_photos;
drop policy if exists "photos: partner remove" on public.country_photos;
create policy "photos: partner add"    on public.country_photos for insert with check (public.can_edit_country(country_id) and uploaded_by = auth.uid());
create policy "photos: partner remove" on public.country_photos for delete using (public.can_edit_country(country_id));

-- 사진 파일 저장소 (Storage)
do $$ begin
  if exists (select 1 from information_schema.tables where table_schema = 'storage' and table_name = 'objects') then
    drop policy if exists "svm: partner photo upload" on storage.objects;
    drop policy if exists "svm: partner photo remove" on storage.objects;
    create policy "svm: partner photo upload" on storage.objects for insert to authenticated
      with check (bucket_id = 'country-photos' and exists (select 1 from public.countries c
        where lower(c.code) = (storage.foldername(name))[1] and public.can_edit_country(c.id)));
    create policy "svm: partner photo remove" on storage.objects for delete to authenticated
      using (bucket_id = 'country-photos' and exists (select 1 from public.countries c
        where lower(c.code) = (storage.foldername(name))[1] and public.can_edit_country(c.id)));
  end if;
end $$;
