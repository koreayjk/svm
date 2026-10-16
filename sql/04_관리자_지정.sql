-- =====================================================================
-- SVM App — 04_관리자_지정.sql
-- 1) 먼저 앱에서 관리자 계정으로 회원가입(이메일 인증 완료)하세요.
-- 2) 아래 이메일을 실제 관리자 이메일로 바꾼 뒤 SQL Editor 에서 실행하세요.
--    여러 명이면 이메일을 콤마로 추가하세요.
-- =====================================================================

update public.profiles
set role = 'admin'
where lower(email) in (
  lower('admin@example.com')
  -- , lower('second-admin@example.com')
);

-- 결과 확인
select id, name, email, role from public.profiles where role = 'admin';

-- (참고) 관리자 해제:
-- update public.profiles set role = 'member' where lower(email) = lower('admin@example.com');
