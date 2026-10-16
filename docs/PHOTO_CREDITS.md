# 임시 국가 사진 출처

SVM 자체 사진을 올리기 전까지 쓰는 기본 이미지입니다 (`assets/countries/*.jpg`, 1000×750 으로 줄여 저장).
모두 [Pexels 라이선스](https://www.pexels.com/license/) — 상업·비상업 무료 사용, 출처 표기 의무 없음 (앱 나라 상세 화면에 사진가 이름을 함께 표시합니다).

선교지 보호 원칙에 따라 **사람 얼굴이 드러나지 않는 풍경·도시 사진**만 골랐습니다.

| 나라 | 파일 | 장면 | 사진가 | 원본 |
|---|---|---|---|---|
| 한국 | `kr.jpg` | 광화문 (경복궁) | 대정 김 | https://www.pexels.com/photo/the-gwanghwamun-gate-of-the-gyeongbokgung-palace-6427160/ |
| 필리핀 | `ph.jpg` | 바나우에 계단식 논 | Palu Malerba | https://www.pexels.com/photo/aerial-photography-of-rice-terraces-2516406/ |
| 말레이시아 | `my.jpg` | 쿠알라룸푸르 스카이라인 | Yulia | https://www.pexels.com/photo/high-rise-buildings-of-kuala-lumpur-3815533/ |
| 태국 | `th.jpg` | 치앙마이 계단식 논 | Pitipat Usanakornkul | https://www.pexels.com/photo/landscape-photo-of-beautiful-terrace-rice-field-in-chiang-mai-thailand-16592316/ |
| 멕시코 | `mx.jpg` | 과나후아토 거리 | Willy Méndez | https://www.pexels.com/photo/vibrant-street-scene-in-guanajuato-mexico-29159332/ |
| 일본 | `jp.jpg` | 후지산과 츄레이토 탑 | Regev Ace Subay | https://www.pexels.com/photo/pagoda-and-mount-fuji-in-spring-4336279/ |
| 이집트 | `eg.jpg` | 카이로 나일강변 | Yasser Amin | https://www.pexels.com/photo/cairo-skyscrapers-on-the-nile-23314700/ |

## 우리 사진으로 바꾸는 방법
1. Supabase **Storage → country-photos** 버킷에 사진 업로드 → 공개 URL 복사
2. SQL Editor 에서:
   ```sql
   insert into country_photos (country_id, url, sort_order)
   select id, 'https://…/country-photos/korea-1.jpg', 0 from countries where code = 'KR';
   ```
3. 앱을 새로고침하면 해당 나라만 우리 사진으로 바뀝니다 (나머지는 기본 사진 유지).
