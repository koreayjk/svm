-- =====================================================================
-- SVM App — 03_국가_시드.sql (명세 v2)
-- 초기 7개국 + 기본 앱 설정(제공/준비 항목, 파송 시즌) + 공통 준비물 + 주일·금요 모임 예시
-- 내용은 초안입니다. 관리자 화면 또는 이 파일을 수정해 실제 내용으로 바꾸세요.
-- 다시 실행하면 국가 기본 정보가 아래 값으로 덮어써집니다 (사진·채팅·이름 쓰기 등은 유지).
-- =====================================================================

-- INTO THE WORLD 현지 사역 기본 문구 (국가별로 수정 가능)
--   EN: Up to 5 English conversation classes a day · serve with local churches and missionaries ·
--       share the gospel and teach the Bible · build friendships with local young people · cross-cultural discipleship
insert into public.countries
  (code, name_en, name_ko, is_sensitive, sort_order,
   intro, intro_ko, ministry, ministry_ko, daily_life, daily_life_ko,
   language, language_ko, housing, housing_ko)
values
  ('KR', 'South Korea', '한국', false, 1,
   'Partner churches across Korea welcome students to serve alongside local congregations.',
   '한국 전역의 협력 교회들이 학생들과 함께 지역 교회를 섬깁니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Korea: campus outreach and English camps with partner churches.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n한국에서는: 협력 교회와 함께하는 캠퍼스 전도와 영어 캠프.',
   'Fast-paced city life with excellent public transit. Four distinct seasons — hot, humid summers and cold winters.',
   '대중교통이 편리한 도시 생활. 사계절이 뚜렷하며 여름은 덥고 습하고 겨울은 춥습니다.',
   'Korean (greetings and the gospel message). English for classes.',
   '한국어 (인사와 복음 메시지). 수업은 영어로 진행합니다.',
   'Host-church housing with all meals provided.',
   '현지 교회 숙소, 모든 식사 제공.'),

  ('PH', 'Philippines', '필리핀', false, 2,
   'A warm, open culture with many churches eager for young workers.',
   '따뜻하고 열린 문화, 젊은 사역자를 기다리는 교회가 많습니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn the Philippines: village evangelism and children''s programs.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n필리핀에서는: 마을 전도와 어린이 프로그램.',
   'Tropical climate — hot year-round with a rainy season (June–November). Family-centered community life.',
   '열대 기후 — 연중 덥고 6~11월은 우기. 가족 중심의 공동체 생활.',
   'Tagalog/Filipino; English is widely spoken.',
   '타갈로그어(필리핀어). 영어가 널리 통용됩니다.',
   'Mission house or host family, with all meals provided.',
   '선교관 또는 홈스테이, 모든 식사 제공.'),

  ('MY', 'Malaysia', '말레이시아', false, 3,
   'A multi-ethnic nation where Malay, Chinese and Indian cultures meet.',
   '말레이·중국·인도 문화가 어우러진 다민족 국가입니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Malaysia: student ministry and community care.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n말레이시아에서는: 학생 사역과 지역 돌봄.',
   'Hot and humid year-round. Diverse food culture; modest dress is expected.',
   '연중 덥고 습함. 다양한 음식 문화, 단정한 복장이 필요합니다.',
   'Malay; English and Chinese are commonly used.',
   '말레이어. 영어와 중국어도 많이 사용됩니다.',
   'Church guest rooms or mission house, with all meals provided.',
   '교회 게스트룸 또는 선교관, 모든 식사 제공.'),

  ('TH', 'Thailand', '태국', false, 4,
   'The "Land of Smiles" — a Buddhist-majority country with a growing church.',
   '"미소의 나라" — 불교 국가이지만 교회가 성장하고 있습니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Thailand: school English classes and village visits.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n태국에서는: 학교 영어 수업과 마을 방문.',
   'Tropical: hot season (Mar–May), rainy season (Jun–Oct), cool season (Nov–Feb). Respect for elders and the monarchy is important.',
   '열대 기후: 더운 철(3~5월), 우기(6~10월), 시원한 철(11~2월). 어른과 왕실에 대한 존중이 중요합니다.',
   'Thai.',
   '태국어.',
   'Mission center or host church, with all meals provided.',
   '선교센터 또는 현지 교회, 모든 식사 제공.'),

  ('MX', 'Mexico', '멕시코', false, 5,
   'A close neighbor with vibrant churches and great openness to the gospel.',
   '가까운 이웃 나라, 활기찬 교회와 복음에 대한 열린 마음.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Mexico: street and village evangelism and VBS.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n멕시코에서는: 거리·마을 전도와 여름성경학교.',
   'Climate varies by region — dry heat in the north, mild in the central highlands. Family and hospitality are central.',
   '지역마다 기후가 다름 — 북부는 건조하고 덥고, 중부 고원은 온화합니다. 가족과 환대가 중심인 문화.',
   'Spanish.',
   '스페인어.',
   'Host families or church facilities, with all meals provided.',
   '홈스테이 또는 교회 시설, 모든 식사 제공.'),

  ('JP', 'Japan', '일본', false, 6,
   'Less than 1% of Japan is Christian — one of the largest unreached peoples.',
   '기독교인이 1% 미만 — 가장 큰 미전도 종족 중 하나입니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Japan: English cafés with small local churches.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n일본에서는: 작은 지역 교회와 함께하는 영어 카페.',
   'Clean, orderly and punctual society. Four seasons; humid summers.',
   '깨끗하고 질서 있으며 시간을 잘 지키는 사회. 사계절, 습한 여름.',
   'Japanese.',
   '일본어.',
   'Church housing or mission house, with all meals provided.',
   '교회 숙소 또는 선교관, 모든 식사 제공.'),

  ('EG', 'Egypt', '이집트', true, 7,
   'One of the oldest Christian communities in the world lives here.',
   '세계에서 가장 오래된 기독교 공동체 중 하나가 있는 곳입니다.',
   E'INTO THE WORLD — English conversation classes and quiet, relational ministry alongside local believers. Details are shared in person after approval.',
   E'INTO THE WORLD — 영어 회화 수업과 현지 성도와 함께하는 조용한 관계 중심 사역. 세부 내용은 승인 후 대면으로 안내합니다.',
   'Hot, dry desert climate. Conservative culture — modest dress and discretion are essential.',
   '덥고 건조한 사막 기후. 보수적인 문화 — 단정한 복장과 신중함이 꼭 필요합니다.',
   'Arabic (Egyptian dialect).',
   '아랍어 (이집트 방언).',
   'Arranged by the local team; details are shared after approval.',
   '현지 팀이 준비합니다. 세부 사항은 승인 후 안내됩니다.')
on conflict (code) do update set
  name_en = excluded.name_en, name_ko = excluded.name_ko,
  is_sensitive = excluded.is_sensitive, sort_order = excluded.sort_order,
  intro = excluded.intro, intro_ko = excluded.intro_ko,
  ministry = excluded.ministry, ministry_ko = excluded.ministry_ko,
  daily_life = excluded.daily_life, daily_life_ko = excluded.daily_life_ko,
  language = excluded.language, language_ko = excluded.language_ko,
  housing = excluded.housing, housing_ko = excluded.housing_ko,
  is_active = true;

-- v1 시드로 중국(CN)이 들어간 DB 라면 숨김 처리 (데이터는 보존, 관리자 화면에서 다시 켤 수 있음)
update public.countries set is_active = false where code = 'CN';

-- 기본 앱 설정
insert into public.app_settings (key, value) values
  ('require_graduation_to_apply', 'false'::jsonb),   -- 초반에는 누구나 신청 가능
  ('sensitive_photo_block',       'true'::jsonb),    -- 민감 국가 후기 사진 업로드 차단
  ('gathering_location',          '"Church — Bryan/College Station, TX"'::jsonb),
  -- 국가 페이지 고정 블록: 선교지에서 제공
  ('provided_items', '[
     {"en": "Housing and all meals",                       "ko": "숙소와 모든 식사"},
     {"en": "Ministry and activity costs",                 "ko": "사역·활동 비용"},
     {"en": "Local staff support and orientation",         "ko": "현지 스태프 지원과 오리엔테이션"}
   ]'::jsonb),
  -- 국가 페이지 고정 블록: 내가 준비할 것
  ('prepare_items', '[
     {"en": "Round-trip airfare",                          "ko": "왕복 항공권"},
     {"en": "Personal spending money and a valid passport", "ko": "개인 용돈과 유효한 여권"},
     {"en": "A heart ready to learn",                      "ko": "배우려는 마음"}
   ]'::jsonb),
  -- 정규 파송 시즌
  ('mission_seasons', '{
     "en": "December · January · May–August (and anytime else)",
     "ko": "12월 · 1월 · 5–8월 (그 외에도 언제든)"
   }'::jsonb)
on conflict (key) do nothing;

-- 모든 국가 공통 준비물 (country_id = null)
insert into public.checklist_items (country_id, label_en, label_ko, sort_order)
select null, v.label_en, v.label_ko, v.sort_order
from (values
  ('Passport (valid 6+ months after return)', '여권 (귀국일 기준 6개월 이상 유효)', 1),
  ('Visa / entry requirements checked',        '비자·입국 요건 확인',               2),
  ('Round-trip flight booked',                 '왕복 항공권 예약',                   3),
  ('Vaccinations / health check',              '예방접종·건강 검진',                 4),
  ('Travel insurance',                         '여행자 보험',                       5),
  ('Emergency contacts shared with SVM',       'SVM에 비상 연락처 제출',             6),
  ('Packing (clothes, meds, Bible)',           '짐 꾸리기 (옷, 상비약, 성경)',        7)
) as v(label_en, label_ko, sort_order)
where not exists (select 1 from public.checklist_items where country_id is null);

-- 정기 모임 예시 — 다음 주일 미션 게더링 / 다음 금요 트레이닝 나이트 (없을 때만)
--   금요일 시간(오후 7–9시)은 예시입니다. 실제 시간으로 바꾸세요.
insert into public.gatherings (type, date, start_time, end_time, location, title)
select 'sunday', (current_date + ((7 - extract(dow from current_date)::int) % 7))::date,
       '14:00', '16:00', 'Church — Bryan/College Station, TX', 'Sunday Mission Gathering'
where not exists (select 1 from public.gatherings where type = 'sunday' and date >= current_date);

insert into public.gatherings (type, date, start_time, end_time, location, title)
select 'friday', (current_date + ((12 - extract(dow from current_date)::int) % 7))::date,
       '19:00', '21:00', 'Church — Bryan/College Station, TX', 'Friday Training Night — DNA2 · PST'
where not exists (select 1 from public.gatherings where type = 'friday' and date >= current_date);

-- 특별 이벤트: SVM 미션 컨퍼런스 2026 (발족식) — 시간·장소가 정해지면 수정하세요
insert into public.events
  (title_en, title_ko, subtitle_en, subtitle_ko, description_en, description_ko,
   starts_at, all_day, location, is_featured)
select
  'SVM Mission Conference 2026', 'SVM 미션 컨퍼런스 2026',
  'Launch night of the Student Volunteer Movement', '학생자원운동 발족식',
  E'The launch of SVM in Bryan/College Station.\nTent Village — walk the nation booths and sign your nation.\nSign up on site with the QR code, explore the fields, and apply.\nFirst look at the SVM metaverse mission space (teaser).',
  E'브라이언/컬리지 스테이션 SVM 발족식.\n텐트 빌리지 — 나라별 부스를 돌며 내 나라에 이름 쓰기.\n현장 QR로 가입하고, 선교지를 둘러보고, 신청까지.\nSVM 메타버스 선교 공간 예고편 첫 공개.',
  '2026-11-20 00:00:00 America/Chicago', true, 'Bryan/College Station, TX', true
where not exists (select 1 from public.events where title_en = 'SVM Mission Conference 2026');
