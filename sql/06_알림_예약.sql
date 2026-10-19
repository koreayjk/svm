-- SVM 자동 알림 예약 (출발 준비 · 보험 증서 · 안부 체크인 · 귀국 후기)
-- 순서: sql/01_스키마.sql → sql/02_RLS.sql 을 먼저 실행한 뒤, 이 파일을 한 번만 실행합니다.
-- 먼저 Supabase 대시보드 → Database → Extensions → "pg_cron" 을 켜 주세요.
-- 매일 15:00 UTC (미국 중부 오전 9~10시, 한국 밤 12시)에 send_reminders() 를 부릅니다.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('svm-reminders', '0 15 * * *', 'select public.send_reminders()');
    raise notice 'svm-reminders 예약 완료 (매일 15:00 UTC)';
  else
    raise notice 'pg_cron 이 꺼져 있습니다. Database → Extensions 에서 켠 뒤 다시 실행하세요.';
  end if;
end $$;
