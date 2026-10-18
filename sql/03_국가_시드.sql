-- =====================================================================
-- SVM App — 03_국가_시드.sql (명세 v2)
-- 초기 7개국 + 기본 앱 설정(제공/준비 항목, 파송 시즌) + 공통 준비물 + 주일 미션 게더링
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
   'Simple host-church housing; meals shared with the church.',
   '현지 교회 숙소, 현지 교회와 소박하게 함께 식사.'),

  ('PH', 'Philippines', '필리핀', false, 2,
   'A warm, open culture with many churches eager for young workers.',
   '따뜻하고 열린 문화, 젊은 사역자를 기다리는 교회가 많습니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn the Philippines: village evangelism and children''s programs.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n필리핀에서는: 마을 전도와 어린이 프로그램.',
   'Tropical climate — hot year-round with a rainy season (June–November). Family-centered community life.',
   '열대 기후 — 연중 덥고 6~11월은 우기. 가족 중심의 공동체 생활.',
   'Tagalog/Filipino; English is widely spoken.',
   '타갈로그어(필리핀어). 영어가 널리 통용됩니다.',
   'Mission house or host family; simple shared meals.',
   '선교관 또는 홈스테이, 현지 교회와 소박하게 함께 식사.'),

  ('MY', 'Malaysia', '말레이시아', false, 3,
   'A multi-ethnic nation where Malay, Chinese and Indian cultures meet.',
   '말레이·중국·인도 문화가 어우러진 다민족 국가입니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Malaysia: student ministry and community care.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n말레이시아에서는: 학생 사역과 지역 돌봄.',
   'Hot and humid year-round. Diverse food culture; modest dress is expected.',
   '연중 덥고 습함. 다양한 음식 문화, 단정한 복장이 필요합니다.',
   'Malay; English and Chinese are commonly used.',
   '말레이어. 영어와 중국어도 많이 사용됩니다.',
   'Church guest room or mission house; simple shared meals.',
   '교회 게스트룸 또는 선교관, 현지 교회와 소박하게 함께 식사.'),

  ('TH', 'Thailand', '태국', false, 4,
   'The "Land of Smiles" — a Buddhist-majority country with a growing church.',
   '"미소의 나라" — 불교 국가이지만 교회가 성장하고 있습니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Thailand: school English classes and village visits.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n태국에서는: 학교 영어 수업과 마을 방문.',
   'Tropical: hot season (Mar–May), rainy season (Jun–Oct), cool season (Nov–Feb). Respect for elders and the monarchy is important.',
   '열대 기후: 더운 철(3~5월), 우기(6~10월), 시원한 철(11~2월). 어른과 왕실에 대한 존중이 중요합니다.',
   'Thai.',
   '태국어.',
   'Mission center or host church; simple shared meals.',
   '선교센터 또는 현지 교회, 현지 교회와 소박하게 함께 식사.'),

  ('MX', 'Mexico', '멕시코', false, 5,
   'A close neighbor with vibrant churches and great openness to the gospel.',
   '가까운 이웃 나라, 활기찬 교회와 복음에 대한 열린 마음.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Mexico: street and village evangelism and VBS.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n멕시코에서는: 거리·마을 전도와 여름성경학교.',
   'Climate varies by region — dry heat in the north, mild in the central highlands. Family and hospitality are central.',
   '지역마다 기후가 다름 — 북부는 건조하고 덥고, 중부 고원은 온화합니다. 가족과 환대가 중심인 문화.',
   'Spanish.',
   '스페인어.',
   'Host families or church rooms; simple shared meals.',
   '홈스테이 또는 교회 시설, 현지 교회와 소박하게 함께 식사.'),

  ('JP', 'Japan', '일본', false, 6,
   'Less than 1% of Japan is Christian — one of the largest unreached peoples.',
   '기독교인이 1% 미만 — 가장 큰 미전도 종족 중 하나입니다.',
   E'INTO THE WORLD — up to 5 English conversation classes a day, serving with local churches and missionaries, sharing the gospel and teaching the Bible, building friendships with local young people, and cross-cultural discipleship.\nIn Japan: English cafés with small local churches.',
   E'INTO THE WORLD — 하루 최대 5회 영어 회화 수업, 현지 교회·선교사와 동역, 복음 전하기와 성경 수업, 현지 청년과의 관계, 교차문화 제자훈련.\n일본에서는: 작은 지역 교회와 함께하는 영어 카페.',
   'Clean, orderly and punctual society. Four seasons; humid summers.',
   '깨끗하고 질서 있으며 시간을 잘 지키는 사회. 사계절, 습한 여름.',
   'Japanese.',
   '일본어.',
   'Church housing or mission house; simple shared meals.',
   '교회 숙소 또는 선교관, 현지 교회와 소박하게 함께 식사.'),

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
  ('gathering_location',          '"IM Friend Baptist Church · 408 E 24th St, Bryan, TX 77803"'::jsonb),
  -- 국가 페이지 고정 블록: 현지에서의 생활 (선교지는 특별히 준비하지 않음 — 있는 그대로 함께)
  ('provided_items', '[
     {"en": "Life with the local church, as they live",          "ko": "현지 교회와 함께, 그들이 사는 그대로"},
     {"en": "Simple local meals and a shared room or homestay",  "ko": "소박한 현지 음식, 함께 쓰는 방이나 홈스테이"},
     {"en": "Your SVM country leader looks after you",           "ko": "SVM 나라 리더가 돌봐 줍니다"}
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

-- 예전 문구("숙소와 모든 식사" 제공)로 저장돼 있으면 새 문구로 바꿈 (관리자가 직접 고친 내용은 그대로)
update public.app_settings set value = '[
     {"en": "Life with the local church, as they live",          "ko": "현지 교회와 함께, 그들이 사는 그대로"},
     {"en": "Simple local meals and a shared room or homestay",  "ko": "소박한 현지 음식, 함께 쓰는 방이나 홈스테이"},
     {"en": "Your SVM country leader looks after you",           "ko": "SVM 나라 리더가 돌봐 줍니다"}
   ]'::jsonb
 where key = 'provided_items' and value::text like '%Housing and all meals%';

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

-- 정기 모임 — 매주 주일 오후 2–4시 미션 게더링 하나뿐입니다 (다음 주일 행이 없을 때만 추가)
insert into public.gatherings (type, date, start_time, end_time, location, title)
select 'sunday', (current_date + ((7 - extract(dow from current_date)::int) % 7))::date,
       '14:00', '16:00', 'IM Friend Baptist Church · 408 E 24th St, Bryan, TX 77803', 'Sunday Mission Gathering'
where not exists (select 1 from public.gatherings where type = 'sunday' and date >= current_date);

-- 주일 미션 게더링 장소: IM Friend Baptist Church (예전 임시 장소 문구를 바꿈)
update public.app_settings set value = '"IM Friend Baptist Church · 408 E 24th St, Bryan, TX 77803"'::jsonb
 where key = 'gathering_location' and value = '"Church — Bryan/College Station, TX"'::jsonb;
update public.gatherings set location = 'IM Friend Baptist Church · 408 E 24th St, Bryan, TX 77803' where location = 'Church — Bryan/College Station, TX';

-- 금요 모임은 없습니다 — 예전 시드로 들어간 금요 트레이닝 나이트 행을 지웁니다
delete from public.gatherings where type = 'friday' and title = 'Friday Training Night — DNA2 · PST';

-- ③ 언어 훈련: 복음 메시지 예시 (5문장 × 7개 언어) — tools/gospel_sample.py 로 생성
--   ⚠️ 예시 번역입니다. 현지 사역자가 검수한 문장으로 바꾸세요 (앱: 관리 → 훈련 → 복음 메시지 문장)
insert into public.gospel_messages (title, base_text, sort_order)
select 'The Good News (sample)', 'God loves you. All people have sinned and are separated from God. Jesus died on the cross for our sins and rose again. If you believe in Jesus, you receive forgiveness and eternal life. Will you receive Jesus today?', 1
where not exists (select 1 from public.gospel_messages);

with m as (select id from public.gospel_messages order by sort_order, id limit 1),
base(seq, en, ko) as (values
    (1, 'God loves you.', '하나님은 당신을 사랑하십니다.'),
    (2, 'All people have sinned and are separated from God.', '모든 사람은 죄를 지어 하나님과 멀어졌습니다.'),
    (3, 'Jesus died on the cross for our sins and rose again.', '예수님은 우리 죄를 위해 십자가에서 죽으시고 다시 살아나셨습니다.'),
    (4, 'If you believe in Jesus, you receive forgiveness and eternal life.', '예수님을 믿으면 죄 용서와 영원한 생명을 받습니다.'),
    (5, 'Will you receive Jesus today?', '오늘 예수님을 영접하시겠어요?')),
loc(code, seq, local_text, pron) as (values
    ('KR', 1, '하나님은 당신을 사랑하십니다.', 'Hananim-eun dangsin-eul saranghasimnida.'),
    ('KR', 2, '모든 사람은 죄를 지어 하나님과 멀어졌습니다.', 'Modeun saram-eun joe-reul jieo Hananim-gwa meoreojyeotseumnida.'),
    ('KR', 3, '예수님은 우리 죄를 위해 십자가에서 죽으시고 다시 살아나셨습니다.', 'Yesunim-eun uri joe-reul wihae sipjaga-eseo jugeusigo dasi sarananasyeotseumnida.'),
    ('KR', 4, '예수님을 믿으면 죄 용서와 영원한 생명을 받습니다.', 'Yesunim-eul mideumyeon joe yongseo-wa yeongwonhan saengmyeong-eul batseumnida.'),
    ('KR', 5, '오늘 예수님을 영접하시겠어요?', 'Oneul Yesunim-eul yeongjeophasigesseoyo?'),
    ('PH', 1, 'Mahal ka ng Diyos.', 'ma-HAL ka nang dee-YOS'),
    ('PH', 2, 'Lahat ng tao ay nagkasala at nahiwalay sa Diyos.', 'la-HAT nang TA-o ai nag-ka-sa-LA at na-hi-wa-LAI sa dee-YOS'),
    ('PH', 3, 'Si Hesus ay namatay sa krus para sa ating mga kasalanan at muling nabuhay.', 'see HE-sus ai na-ma-TAI sa KROOS PA-ra sa A-ting ma-NGA ka-sa-LA-nan at MOO-ling na-BOO-hai'),
    ('PH', 4, 'Kung sasampalataya ka kay Hesus, tatanggap ka ng kapatawaran at buhay na walang hanggan.', 'kung sa-sam-pa-la-ta-YA ka kai HE-sus, ta-tang-GAP ka nang ka-pa-ta-WA-ran at BOO-hai na wa-LANG hang-GAN'),
    ('PH', 5, 'Tatanggapin mo ba si Hesus ngayon?', 'ta-tang-GA-pin mo ba see HE-sus nga-YON?'),
    ('MY', 1, 'Tuhan mengasihi anda.', 'TOO-han meng-a-SEE-hee AN-da'),
    ('MY', 2, 'Semua manusia telah berdosa dan terpisah daripada Tuhan.', 'se-MOO-a ma-NOO-sia te-LAH ber-DO-sa dan ter-PEE-sah da-ree-PA-da TOO-han'),
    ('MY', 3, 'Yesus mati di kayu salib kerana dosa-dosa kita dan bangkit semula.', 'YE-sus MA-tee dee KA-yoo SA-lib ke-RA-na DO-sa DO-sa KEE-ta dan BANG-kit se-MOO-la'),
    ('MY', 4, 'Jika anda percaya kepada Yesus, anda menerima pengampunan dan hidup yang kekal.', 'JEE-ka AN-da per-CHA-ya ke-PA-da YE-sus, AN-da me-ne-REE-ma peng-am-POO-nan dan HEE-dup yang ke-KAL'),
    ('MY', 5, 'Adakah anda mahu menerima Yesus hari ini?', 'a-DA-kah AN-da MA-hoo me-ne-REE-ma YE-sus HA-ree EE-nee?'),
    ('TH', 1, 'พระเจ้าทรงรักคุณ', 'Phra-jao song rak khun'),
    ('TH', 2, 'ทุกคนทำบาปและแยกจากพระเจ้า', 'Thuk khon tham baap lae yaek jaak Phra-jao'),
    ('TH', 3, 'พระเยซูสิ้นพระชนม์บนไม้กางเขนเพื่อบาปของเรา และทรงเป็นขึ้นมาใหม่', 'Phra-Yesu sin phra-chon bon mai-kaang-khen phuea baap khong rao, lae song pen khuen maa mai'),
    ('TH', 4, 'ถ้าคุณเชื่อในพระเยซู คุณจะได้รับการอภัยบาปและชีวิตนิรันดร์', 'Thaa khun chuea nai Phra-Yesu, khun ja dai rap kaan a-phai baap lae chii-wit ni-ran'),
    ('TH', 5, 'วันนี้คุณจะรับพระเยซูไหม', 'Wan-nii khun ja rap Phra-Yesu mai?'),
    ('MX', 1, 'Dios te ama.', 'DYOS teh AH-mah'),
    ('MX', 2, 'Todos hemos pecado y estamos separados de Dios.', 'TOH-dohs EH-mohs peh-KAH-doh ee ehs-TAH-mohs seh-pah-RAH-dohs deh DYOS'),
    ('MX', 3, 'Jesús murió en la cruz por nuestros pecados y resucitó.', 'heh-SOOS moo-RYOH ehn lah KROOS pohr NWEHS-trohs peh-KAH-dohs ee reh-soo-see-TOH'),
    ('MX', 4, 'Si crees en Jesús, recibes el perdón y la vida eterna.', 'see KREH-ehs ehn heh-SOOS, reh-SEE-behs ehl pehr-DOHN ee lah VEE-dah eh-TEHR-nah'),
    ('MX', 5, '¿Quieres recibir a Jesús hoy?', 'KYEH-rehs reh-see-BEER ah heh-SOOS oy?'),
    ('JP', 1, '神様はあなたを愛しています。', 'Kamisama wa anata o aishite imasu.'),
    ('JP', 2, 'すべての人は罪を犯し、神様から離れています。', 'Subete no hito wa tsumi o okashi, Kamisama kara hanarete imasu.'),
    ('JP', 3, 'イエス様は私たちの罪のために十字架で死に、よみがえられました。', 'Iesu-sama wa watashitachi no tsumi no tame ni jūjika de shini, yomigaeraremashita.'),
    ('JP', 4, 'イエス様を信じるなら、罪の赦しと永遠のいのちを受けます。', 'Iesu-sama o shinjiru nara, tsumi no yurushi to eien no inochi o ukemasu.'),
    ('JP', 5, '今日、イエス様を受け入れますか？', 'Kyō, Iesu-sama o ukeiremasu ka?'),
    ('EG', 1, 'ربنا بيحبك.', 'Rabbena biyḥebbak.'),
    ('EG', 2, 'كل الناس أخطأوا وبعدوا عن ربنا.', 'Koll en-nās akhṭa’u we be‘du ‘an Rabbena.'),
    ('EG', 3, 'يسوع مات على الصليب علشان خطايانا وقام من الأموات.', 'Yasū‘ māt ‘ala eṣ-ṣalīb ‘ashān khaṭayāna we ’ām men el-amwāt.'),
    ('EG', 4, 'لو آمنت بيسوع، هتاخد غفران الخطايا والحياة الأبدية.', 'Law āmant be-Yasū‘, hatākhod ghofrān el-khaṭāya wel-ḥayāh el-abadeyya.'),
    ('EG', 5, 'تحب تقبل يسوع النهارده؟', 'Teḥebb te’bal Yasū‘ en-nahārda?'))
insert into public.gospel_sentences (message_id, country_id, seq, source_text, source_ko, local_text, pronunciation)
select m.id, c.id, b.seq, b.en, b.ko, l.local_text, l.pron
from m cross join base b
join loc l on l.seq = b.seq
join public.countries c on c.code = l.code
where not exists (select 1 from public.gospel_sentences s where s.message_id = m.id and s.country_id = c.id);


-- ③ 선교 교육: 첫 강의 2개 (SVM 비전 영상) — 앱의 관리 → 훈련에서 추가·수정하세요
insert into public.courses (title_en, title_ko, video_url, description, description_ko, sort_order, required)
select v.* from (values
  ('What is SVM? The vision', 'SVM은 무엇인가: 비전', 'https://www.youtube.com/watch?v=Ig5I70_UcXc',
   'Watch the SVM vision. Then write: what stirred your heart, and what is one step you will take this week?',
   'SVM 비전 영상을 보고 적어 보세요: 무엇이 마음을 움직였나요? 이번 주에 내딛을 한 걸음은 무엇인가요?', 1, true),
  ('The call behind Mission Conference 2026', '미션 컨퍼런스 2026의 부르심', 'https://www.youtube.com/watch?v=YbZLqIe8NWE',
   'Watch the call behind the launch. Then write: which nation is on your heart, and why?',
   '발족식에 담긴 부르심을 보고 적어 보세요: 마음에 품은 나라는 어디이고, 왜인가요?', 2, true)
) as v(title_en, title_ko, video_url, description, description_ko, sort_order, required)
where not exists (select 1 from public.courses);

-- 특별 이벤트: SVM 미션 컨퍼런스 2026 (발족식) — 11/20(금) 오후 6시 입장. 장소가 정해지면 location 을 수정하세요
insert into public.events
  (title_en, title_ko, subtitle_en, subtitle_ko, description_en, description_ko,
   starts_at, all_day, location, link_url, is_featured)
select
  'SVM Mission Conference 2026', 'SVM 미션 컨퍼런스 2026',
  'Launch night of the Student Volunteer Movement', '학생자원운동 발족식',
  E'The launch of SVM in Bryan/College Station.\nTent Village — walk the nation booths and sign your nation.\nSign up on site with the QR code, explore the fields, and apply.\nFirst look at the SVM metaverse mission space (teaser).',
  E'브라이언/컬리지 스테이션 SVM 발족식.\n텐트 빌리지 — 나라별 부스를 돌며 내 나라에 이름 쓰기.\n현장 QR로 가입하고, 선교지를 둘러보고, 신청까지.\nSVM 메타버스 선교 공간 예고편 첫 공개.',
  '2026-11-20 18:00:00 America/Chicago', false,
  'Bryan–College Station, TX · venue announced soon', '../conference/#register', true
where not exists (select 1 from public.events where title_en = 'SVM Mission Conference 2026');

-- 예전 시드(하루 종일 일정)로 이미 들어간 경우 오후 6시 입장으로 맞춤
update public.events
   set starts_at = '2026-11-20 18:00:00 America/Chicago',
       all_day = false, link_url = coalesce(link_url, '../conference/#register'),
       location = case when location = 'Bryan/College Station, TX' then 'Bryan–College Station, TX · venue announced soon' else location end
 where title_en = 'SVM Mission Conference 2026' and all_day;
