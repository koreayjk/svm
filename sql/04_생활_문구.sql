-- =====================================================================
-- SVM App — 04_생활_문구.sql
-- "선교지에 부담 없이" 문구로 바꾸기: 학생은 항공권만 부담하고,
-- 현지 교회가 사는 그대로 소박하게 함께 지냅니다 (선교지는 특별히 준비하지 않음).
-- 예전 기본 문구일 때만 바꿉니다. 관리자 화면에서 직접 고친 내용은 그대로 둡니다.
-- 여러 번 실행해도 안전합니다.
-- =====================================================================

-- 국가 페이지 "현지에서의 생활" 공통 항목
update public.app_settings set value = '[
   {"en": "Life with the local church, as they live",          "ko": "현지 교회와 함께, 그들이 사는 그대로"},
   {"en": "Simple local meals and a shared room or homestay",  "ko": "소박한 현지 음식, 함께 쓰는 방이나 홈스테이"},
   {"en": "Your SVM country leader looks after you",           "ko": "SVM 나라 리더가 돌봐 줍니다"}
 ]'::jsonb
 where key = 'provided_items' and value::text like '%Housing and all meals%';

-- 나라별 숙소·식사 안내 (예전 기본 문구 → 새 문구)
update public.countries c set housing = v.new_en
  from (values
    ('Host-church housing with all meals provided.',                 'Simple host-church housing; meals shared with the church.'),
    ('Mission house or host family, with all meals provided.',       'Mission house or host family; simple shared meals.'),
    ('Church guest rooms or mission house, with all meals provided.', 'Church guest room or mission house; simple shared meals.'),
    ('Mission center or host church, with all meals provided.',      'Mission center or host church; simple shared meals.'),
    ('Host families or church facilities, with all meals provided.', 'Host families or church rooms; simple shared meals.'),
    ('Church housing or mission house, with all meals provided.',    'Church housing or mission house; simple shared meals.')
  ) as v(old_en, new_en)
 where c.housing = v.old_en;

update public.countries
   set housing_ko = replace(housing_ko, ', 모든 식사 제공.', ', 교회 식구들과 소박하게 함께 식사.')
 where housing_ko like '%, 모든 식사 제공.';

-- 확인용: 바뀐 결과
select code, housing, housing_ko from public.countries order by sort_order;
