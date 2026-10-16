-- =====================================================================
-- SVM App — 03_국가_시드.sql
-- 초기 8개국 + 기본 앱 설정 + 공통 준비물 체크리스트 + 첫 게더링
-- 내용은 초안입니다. 관리자 화면 또는 이 파일을 수정해 실제 내용으로 바꾸세요.
-- 다시 실행하면 국가 기본 정보가 아래 값으로 덮어써집니다 (사진·채팅 등은 유지).
-- =====================================================================

insert into public.countries
  (code, name_en, name_ko, is_sensitive, sort_order,
   intro, intro_ko, ministry, ministry_ko, daily_life, daily_life_ko,
   language, language_ko, housing, housing_ko)
values
  ('KR', 'South Korea', '한국', false, 1,
   'Partner churches across Korea welcome students to serve alongside local congregations.',
   '한국 전역의 협력 교회들이 학생들과 함께 지역 교회를 섬깁니다.',
   'Campus outreach, English camps, youth and children''s ministry with local churches.',
   '캠퍼스 전도, 영어 캠프, 지역 교회와 함께하는 청소년·어린이 사역.',
   'Fast-paced city life with excellent public transit. Four distinct seasons — hot, humid summers and cold winters.',
   '대중교통이 편리한 도시 생활. 사계절이 뚜렷하며 여름은 덥고 습하고 겨울은 춥습니다.',
   'Korean (basic greetings and the gospel message). English is useful for camps.',
   '한국어 (기본 인사와 복음 메시지). 영어 캠프에서는 영어 사용.',
   'Lodging and meals are provided by host churches — you only pay for your flight.',
   '숙식은 현지 교회에서 제공합니다 — 항공권만 준비하세요.'),

  ('PH', 'Philippines', '필리핀', false, 2,
   'A warm, open culture with many churches eager for young workers.',
   '따뜻하고 열린 문화, 젊은 사역자를 기다리는 교회가 많습니다.',
   'Village evangelism, children''s programs, feeding ministry and church planting support.',
   '마을 전도, 어린이 프로그램, 급식 사역, 교회 개척 지원.',
   'Tropical climate — hot year-round with a rainy season (June–November). Family-centered community life.',
   '열대 기후 — 연중 덥고 6~11월은 우기. 가족 중심의 공동체 생활.',
   'Tagalog/Filipino; English is widely spoken.',
   '타갈로그어(필리핀어). 영어가 널리 통용됩니다.',
   'Mission house or host family; meals provided by the local team.',
   '선교관 또는 홈스테이, 식사는 현지 팀이 제공합니다.'),

  ('MY', 'Malaysia', '말레이시아', false, 3,
   'A multi-ethnic nation where Malay, Chinese and Indian cultures meet.',
   '말레이·중국·인도 문화가 어우러진 다민족 국가입니다.',
   'Serving local churches, student ministry, community care and tutoring.',
   '지역 교회 섬김, 학생 사역, 지역 돌봄과 학습 지도.',
   'Hot and humid year-round. Diverse food culture; modest dress is expected.',
   '연중 덥고 습함. 다양한 음식 문화, 단정한 복장이 필요합니다.',
   'Malay; English and Chinese are commonly used.',
   '말레이어. 영어와 중국어도 많이 사용됩니다.',
   'Church guest rooms or mission house; meals provided.',
   '교회 게스트룸 또는 선교관, 식사 제공.'),

  ('TH', 'Thailand', '태국', false, 4,
   'The "Land of Smiles" — a Buddhist-majority country with a growing church.',
   '"미소의 나라" — 불교 국가이지만 교회가 성장하고 있습니다.',
   'English teaching, children''s ministry, village visits and church support.',
   '영어 교육, 어린이 사역, 마을 방문, 교회 지원.',
   'Tropical: hot season (Mar–May), rainy season (Jun–Oct), cool season (Nov–Feb). Respect for elders and the monarchy is important.',
   '열대 기후: 더운 철(3~5월), 우기(6~10월), 시원한 철(11~2월). 어른과 왕실에 대한 존중이 중요합니다.',
   'Thai.',
   '태국어.',
   'Mission center or host church; meals provided.',
   '선교센터 또는 현지 교회, 식사 제공.'),

  ('MX', 'Mexico', '멕시코', false, 5,
   'A close neighbor with vibrant churches and great openness to the gospel.',
   '가까운 이웃 나라, 활기찬 교회와 복음에 대한 열린 마음.',
   'Street and village evangelism, VBS, construction and community service.',
   '거리·마을 전도, 여름성경학교, 건축 봉사, 지역 섬김.',
   'Climate varies by region — dry heat in the north, mild in the central highlands. Family and hospitality are central.',
   '지역마다 기후가 다름 — 북부는 건조하고 덥고, 중부 고원은 온화합니다. 가족과 환대가 중심인 문화.',
   'Spanish.',
   '스페인어.',
   'Host families or church facilities; meals provided.',
   '홈스테이 또는 교회 시설, 식사 제공.'),

  ('EG', 'Egypt', '이집트', true, 6,
   'One of the oldest Christian communities in the world lives here.',
   '세계에서 가장 오래된 기독교 공동체 중 하나가 있는 곳입니다.',
   'Supporting local believers, English programs and quiet relational ministry.',
   '현지 성도 지원, 영어 프로그램, 조용한 관계 중심 사역.',
   'Hot, dry desert climate. Conservative culture — modest dress and discretion are essential.',
   '덥고 건조한 사막 기후. 보수적인 문화 — 단정한 복장과 신중함이 꼭 필요합니다.',
   'Arabic (Egyptian dialect).',
   '아랍어 (이집트 방언).',
   'Arranged by the local team; details are shared after approval.',
   '현지 팀이 준비합니다. 세부 사항은 승인 후 안내됩니다.'),

  ('JP', 'Japan', '일본', false, 7,
   'Less than 1% of Japan is Christian — one of the largest unreached peoples.',
   '기독교인이 1% 미만 — 가장 큰 미전도 종족 중 하나입니다.',
   'Partnering with small local churches, English cafés, campus and community events.',
   '작은 지역 교회와 협력, 영어 카페, 캠퍼스·지역 행사.',
   'Clean, orderly and punctual society. Four seasons; humid summers.',
   '깨끗하고 질서 있으며 시간을 잘 지키는 사회. 사계절, 습한 여름.',
   'Japanese.',
   '일본어.',
   'Church housing or mission house; meals provided.',
   '교회 숙소 또는 선교관, 식사 제공.'),

  ('CN', 'China', '중국', true, 8,
   'A vast nation with a faithful and growing church.',
   '신실하게 성장하는 교회가 있는 넓은 나라입니다.',
   'Relational ministry alongside local partners. Details are shared in person only.',
   '현지 협력자와 함께하는 관계 중심 사역. 세부 내용은 대면으로만 안내합니다.',
   'Climate varies widely by region. Internet services differ from the US.',
   '지역별로 기후 차이가 큽니다. 인터넷 서비스 환경이 미국과 다릅니다.',
   'Mandarin Chinese.',
   '중국어 (보통화).',
   'Arranged by local partners; details are shared after approval.',
   '현지 협력자가 준비합니다. 세부 사항은 승인 후 안내됩니다.')
on conflict (code) do update set
  name_en = excluded.name_en, name_ko = excluded.name_ko,
  is_sensitive = excluded.is_sensitive, sort_order = excluded.sort_order,
  intro = excluded.intro, intro_ko = excluded.intro_ko,
  ministry = excluded.ministry, ministry_ko = excluded.ministry_ko,
  daily_life = excluded.daily_life, daily_life_ko = excluded.daily_life_ko,
  language = excluded.language, language_ko = excluded.language_ko,
  housing = excluded.housing, housing_ko = excluded.housing_ko;

-- 기본 앱 설정
insert into public.app_settings (key, value) values
  ('require_graduation_to_apply', 'false'::jsonb),  -- 초반에는 누구나 신청 가능
  ('sensitive_photo_block',       'true'::jsonb),   -- 민감 국가 후기 사진 업로드 차단
  ('gathering_location',          '"Church — Bryan/College Station, TX"'::jsonb)
on conflict (key) do nothing;

-- 모든 국가 공통 준비물 (country_id = null)
insert into public.checklist_items (country_id, label_en, label_ko, sort_order)
select null, v.label_en, v.label_ko, v.sort_order
from (values
  ('Passport (valid 6+ months after return)', '여권 (귀국일 기준 6개월 이상 유효)', 1),
  ('Visa / entry requirements checked',        '비자·입국 요건 확인',               2),
  ('Flight ticket booked',                     '항공권 예약',                       3),
  ('Vaccinations / health check',              '예방접종·건강 검진',                 4),
  ('Travel insurance',                         '여행자 보험',                       5),
  ('Emergency contacts shared with SVM',       'SVM에 비상 연락처 제출',             6),
  ('Packing (clothes, meds, Bible)',           '짐 꾸리기 (옷, 상비약, 성경)',        7)
) as v(label_en, label_ko, sort_order)
where not exists (select 1 from public.checklist_items where country_id is null);

-- 다음 주일 게더링 1건 (없을 때만)
insert into public.gatherings (date, start_time, end_time, location, title)
select (current_date + ((7 - extract(dow from current_date)::int) % 7))::date,
       '14:00', '16:00', 'Church — Bryan/College Station, TX', 'Weekly Mission Gathering'
where not exists (select 1 from public.gatherings where date >= current_date);
