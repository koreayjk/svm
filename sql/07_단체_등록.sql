-- 컨퍼런스 단체 등록: 단체 이름과 총 인원 (여러 번 실행해도 안전)
alter table public.conference_registrations add column if not exists group_name text check (group_name is null or char_length(group_name) between 1 and 120);
alter table public.conference_registrations add column if not exists group_size int  check (group_size is null or group_size between 2 and 500);
