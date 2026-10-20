// SVM 공통 설정 — 홈페이지(/), 컨퍼런스(/conference/), 앱(/app/)이 함께 씁니다.
// Supabase 대시보드 > Project Settings > API 에서 복사해 넣으세요.
// anon key 만 넣습니다 (공개돼도 괜찮은 키 — 데이터 보호는 RLS 가 담당). service_role key 는 절대 넣지 마세요.
// 비워 두면 앱은 데모 모드로, 컨퍼런스 등록 폼은 "준비 중" 안내로 동작합니다.
window.SVM_CONFIG = {
  SUPABASE_URL: 'https://uafdrygbaloqffhwcebc.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhZmRyeWdiYWxvcWZmaHdjZWJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxODg4NjgsImV4cCI6MjEwNzc2NDg2OH0.UkacLuLRaS_gG1sCxr2InumUkSkduB6vdQmkskdlm9U',
  TIMEZONE: 'America/Chicago',   // Bryan/College Station
  // 온라인 후원 페이지 (Zeffy). 은행 계좌 연결과 테스트 후원이 끝난 뒤에 주소를 넣으면
  // 홈페이지 · 컨퍼런스 · 웹 앱에 '후원하기' 버튼이 나타납니다. 비워 두면 버튼이 보이지 않습니다.
  // https://www.zeffy.com/en-US/donation-form/send-a-student-reach-a-nation
  GIVING_URL: '',
};
