# 임시 국가 사진 출처

SVM 자체 사진을 올리기 전까지 쓰는 기본 이미지입니다 (`assets/countries/*.jpg`, 1000×750 으로 줄여 저장).
모두 [Pexels 라이선스](https://www.pexels.com/license/) — 무료 사용, 출처 표기 의무 없음 (앱 나라 상세 화면에 사진가 이름을 함께 표시합니다).

**선교 활동 장면**이되, 선교지 보호 원칙에 따라 **얼굴이 식별되지 않는 사진**(손·뒷모습·실루엣)만 골랐습니다.
스톡 사진이라 실제 해당 나라에서 찍은 사진은 아닙니다 — 각 나라 사역 내용(시드 문구)에 맞춘 대표 장면입니다.

| 나라 | 파일 | 장면 (사역) | 사진가 | 원본 |
|---|---|---|---|---|
| 한국 | `kr.jpg` | 영어 수업, 손 든 학생들 뒷모습 | Max Fischer | https://www.pexels.com/photo/teacher-teaching-his-students-5212337/ |
| 필리핀 | `ph.jpg` | 어린이 사역, 손 모은 아이들 (위에서) | Kampus Production | https://www.pexels.com/photo/children-having-an-activity-together-8813497/ |
| 말레이시아 | `my.jpg` | 성경 공부 테이블 | Chris Liu | https://www.pexels.com/photo/top-view-of-the-bible-lying-on-a-table-22711047/ |
| 태국 | `th.jpg` | 예배, 손 든 뒷모습 | Daniel Queiroz | https://www.pexels.com/photo/people-doing-worship-9831736/ |
| 멕시코 | `mx.jpg` | 섬김·구제, 음식 상자 전달 | RDNE Stock project | https://www.pexels.com/photo/people-handing-over-a-brown-box-6646903/ |
| 일본 | `jp.jpg` | 예배 실루엣 | Luis Quintero | https://www.pexels.com/photo/silhouette-of-a-man-worshiping-13899663/ |
| 이집트 (민감) | `eg.jpg` | 성경 위 기도하는 손 — 사람 얼굴 없음 | Luis Quintero | https://www.pexels.com/photo/person-placing-hands-on-bible-2258251/ |

## 우리 사진으로 바꾸는 방법
1. Supabase **Storage → country-photos** 버킷에 사진 업로드 → 공개 URL 복사
2. SQL Editor 에서:
   ```sql
   insert into country_photos (country_id, url, sort_order)
   select id, 'https://…/country-photos/korea-1.jpg', 0 from countries where code = 'KR';
   ```
3. 앱을 새로고침하면 해당 나라만 우리 사진으로 바뀝니다 (나머지는 기본 사진 유지).

> 우리 사진도 현지인 얼굴·실명·교회 위치가 드러나지 않게 골라 주세요. 특히 이집트 등 민감 국가.

## 세계지도
`assets/world-dots.svg` — [Natural Earth](https://www.naturalearthdata.com/) 1:110m 육지 데이터(퍼블릭 도메인)를
[world-atlas](https://github.com/topojson/world-atlas)(ISC) 형식으로 받아 점 지도로 변환했습니다.

- `assets/images/` (컨퍼런스 사진: hero, register-bg, tents-*, tile-*, band-pano) — 이전 mc2026 컨퍼런스 사이트에서 쓰던 이미지를 그대로 옮겼습니다. 실제 행사 사진이 생기면 교체하세요.

## 홈페이지 사진 (assets/images/)
모두 Pexels 라이선스. 스톡 사진이며 실제 SVM 활동이 아닙니다 (사진 설명은 비워 두고 실제 사역이라고 주장하지 않습니다).

| 파일 | 용도 | 원본 |
|---|---|---|
| `hero-sunset.jpg` | 히어로 배경 (노을 앞에서 두 팔을 든 실루엣) | https://www.pexels.com/photo/people-silhouette-during-sunset-853168/ |
| `card-flight.jpg` | 가는 사람 카드 | https://www.pexels.com/photo/view-of-airliner-wing-above-the-clouds-2147486/ |
| `card-prayer.jpg`, `band-group.jpg` | 후원 카드, "왜" 섹션 | https://www.pexels.com/photo/group-of-people-praying-in-the-living-room-6860385/ · https://www.pexels.com/photo/group-of-people-praying-together-6860380/ |
| `card-children.jpg` | 현지 교회 카드 | https://www.pexels.com/photo/people-sitting-on-the-floor-9090747/ |
| `ministry-study.jpg` | Into the World | https://www.pexels.com/photo/a-people-doing-bible-study-6860826/ |
