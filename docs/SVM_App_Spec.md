# SVM App — 개발 명세서 (Claude Code 전달용)

> **SVM (Student Volunteer Movement)** — 150년 전 약 2만 명의 대학생을 선교사로 보낸 학생자원운동을 브라이언 컬리지 스테이션에서 다시 일으키는 선교 지원 플랫폼.
> **목표 일정:** 2026년 11월 20일 발족식(미션 컨퍼런스) 전 9개 기능 완성 및 시연
> **2단계(범위 외):** 메타버스 공간 — 발족식에서는 예고편 영상으로만 공개

---

## 0. SVM 핵심 컨셉 (앱 전반 카피·온보딩에 반영)

1. **비행기 값만 낸다** — 선교지에서 숙식을 자체 후원. 학생은 항공권만 부담.
2. **원하는 만큼 머문다** — 1개월로 갔다가 더 있고 싶으면 항공권만 연장. 숙식비 추가 없음 → 단기·중기·장기 모두 가능.
3. **방학마다 간다** — 한 번이 아니라 지속적인 선교.
4. **매주 모인다** — 매주 주일 오후 2:00–4:00 교회에서 오프라인 미션 게더링, 주중에는 앱에서 소통·훈련.

**선교지(초기 8개국, 추후 추가):** 한국, 필리핀, 말레이시아, 태국, 멕시코, 이집트, 일본, 중국
**민감 국가(초기 설정):** 중국, 이집트 — 관리자가 국가별로 on/off 가능해야 함

---

## 1. 기술 스택

- **Frontend:** Vanilla HTML/CSS/JS, 단일 파일(`index.html`), 모바일 우선 반응형
- **Hosting:** GitHub Pages
- **Backend:** Supabase
  - Auth (이메일 로그인)
  - Postgres + RLS
  - Realtime (채팅)
  - Storage (사진·영상 썸네일·음성 파일)
- **PWA:** manifest + service worker로 홈 화면 설치 지원
- **언어:** 영어(기본) / 한국어 전환 토글. 모든 UI 문자열은 `i18n` 객체로 관리
- **SQL 전달 방식:** 스키마·RLS·시드 데이터는 Supabase 대시보드에서 직접 실행할 수 있는 `.sql` 파일로 분리 제공 (파일명 예: `01_스키마.sql`, `02_RLS.sql`, `03_국가_시드.sql`, `04_관리자_지정.sql`)

---

## 2. 회원 등급

| 등급 | 코드 | 권한 |
|---|---|---|
| 일반 회원 | `member` | 둘러보기, 나라방 참여·채팅, 기도 제목, 후기 작성(승인 대기), 교육 수강, 선교 신청 |
| 수료 회원 | `graduate` | 일반 회원 권한 + 수료 배지. (향후 "수료자만 신청 가능" 옵션 켜질 때 신청 자격) |
| 관리자 | `admin` | 신청 승인·상태 변경, 후기 승인/추천, 콘텐츠(국가·교육·메시지·체크리스트) 관리, 모임 공지·출석, 국가 민감도 설정 |

- **설정값 `require_graduation_to_apply`** (기본 `false`): 초반에는 누구나 신청 가능, 추후 관리자가 켜면 수료 회원만 신청 가능.

---

## 3. 9개 기능 상세

### ① 나라별 현지 정보
각 국가 페이지 구성:
1. 현지 사진 (갤러리, Storage 업로드)
2. 사역 소개 — 가면 실제로 어떤 일을 하는지
3. 현지 생활 — 일상, 날씨, 문화
4. 필요한 언어
5. 숙식 안내 — 숙식 제공 방식
- 하단 버튼: **[나라방 들어가기]** **[이 나라로 신청하기]**
- 민감 국가는 상단에 보안 안내 배너 표시
- 관리자가 항목 추가 가능하도록 설계 (향후 확장)

### ② 소통 — 나라별 방
- 나라별 채팅방 (Supabase Realtime)
- **방 참여는 자유** — 여러 나라방 동시 참여 가능, 언제든 나가기/들어가기
- **방 참여 ≠ 신청** — 둘러보기와 실제 신청은 분리
- 내 방 목록, 안 읽은 메시지 표시
- 관리자 메시지 삭제 기능

### ③ 교육
**A. 언어 훈련 — 복음 메시지 현지어 암기**
- 목표: 핵심 복음 메시지를 현지 언어로 완벽 암기
- 메시지는 이미 기본본 존재 → 관리자가 메시지와 국가별 번역을 계속 추가·수정
- 메시지는 문장 단위로 분할 저장 (원문 / 현지어 / 발음 표기 / 음성 파일 선택)
- **무한 반복 모드:** 문장 단위·전체 단위 반복 재생, 재생 속도 조절, 반복 간격 설정
  - 음성: 업로드된 녹음 우선, 없으면 브라우저 `speechSynthesis` TTS
- **집중 훈련 단계 (특수부대식 반복):**
  1. 듣기 — 텍스트 보며 반복
  2. 따라하기 — 문장별 반복
  3. 가리기 — 텍스트 일부/전체 숨기고 말하기
  4. 자가 테스트 — 문장 보고 현지어 떠올리기 → 정답 확인 → 맞음/틀림 체크
- 문장별 숙달도·누적 반복 횟수·연속 학습일 기록

**B. 선교 교육 커리큘럼**
- 영상 강의 (YouTube 등 외부 링크 임베드) — 왜 선교해야 하는가, 하나님이 기뻐하시는 선교 등
- 각 강의 시청 후 **피드백(소감) 작성** → 제출해야 완료 처리
- 관리자가 피드백 열람·코멘트 가능
- 커리큘럼 진행률 표시

**C. 수료**
- 지정된 강의 전부 완료 + 언어 훈련 기준(예: 메시지 1개 이상 자가테스트 통과) 충족 시 수료 신청 → 관리자 승인 → `graduate` 등급 + 배지

### ④ 팀 & 그룹 프로젝트
- 1차 버전: 나라별 느슨한 팀 구조 + 관리자가 팀 생성 및 멤버 지정
- 팀 공간: 팀 게시판, 프로젝트 할 일 목록(담당자·상태·마감일)
- ⚠️ **팀 구성 방식은 추후 결정** — 확장 가능하도록 `teams` / `team_members` 테이블만 일반적으로 설계

### ⑤ 오프라인 연결 — 주간 미션 게더링
- 매주 주일 오후 2:00–4:00, 교회
- 다음 모임 안내와 일정 (홈 화면 상단 카드)
- 설교·나눔 내용 기록 (관리자 작성, 회원 열람)
- 출석 체크 (관리자 체크 또는 모임 시간에 회원이 버튼으로 체크인)
- 개인 출석 기록 보기

### ⑥ 선교 후기 & 간증
- **승인제:** 작성 시 `pending` → 관리자 승인 시 `approved`로 공개 / `rejected`
- 작성 화면에 보안 안내 필수 표시:
  > 현지인 얼굴, 실명, 정확한 장소(교회 위치 등)는 올리지 마세요.
- 민감 국가 후기: 사진 업로드 제한(관리자 설정에 따름) 및 더 엄격한 검토
- 관리자가 좋은 간증을 **추천(고정)** → 홈 메인 노출
- 국가별 후기 모아보기

### ⑦ 신청 & 매칭
**신청서 항목:** 희망 국가, 희망 출발일, 예상 기간, 연락처, 자기소개 / 지원 동기
**상태 흐름:**
```
접수(submitted) → 승인(approved) → 출국 준비(preparing) → 사역 중(on_field) → 귀국(returned)
                 ↘ 반려(rejected)
```
- 승인은 **미국 본부(관리자)** 가 수행
- 현지 선교지는 승인된 명단·도착 일정만 공유받는 구조 (현재는 관리자 화면에서 국가별 명단 출력/내보내기). 향후 현지 담당자 계정 추가 가능하도록 확장 여지 둘 것
- 회원은 내 신청 상태를 타임라인으로 확인
- **연장 신청:** `on_field` 상태에서 [연장 신청] 버튼 → 새 귀국 예정일 입력 → 관리자 승인 → 기간 갱신 (연장 이력 보관)
- `require_graduation_to_apply`가 켜져 있으면 수료 회원만 신청 가능

### ⑧ 기도 제목 나눔
- 나라방 안 기도 제목 게시판 (+ 전체 기도 제목 모아보기)
- **[기도했어요]** 버튼 → 기도한 인원 수 표시 (1인 1회)
- 작성자가 **[응답됨]** 표시 가능 → 응답된 기도는 간증 작성으로 연결 버튼 제공
- 안내 문구: 현지 성도 이름은 이니셜로만 작성

### ⑨ 후원 & 준비물 안내
**준비물 체크리스트**
- 국가별 체크리스트 (여권, 비자, 예방접종, 짐 등) — 관리자 편집
- 신청자 개인별 체크 상태 저장, 진행률 표시

**후원**
- 앱 내 결제 없음 (1차 버전)
- 항공권 후원이 필요한 학생의 사연 게시 (본인 신청 → 관리자 승인 후 공개)
- 각 사연에 교회/단체 후원 링크(외부) 표시
- 향후 결제 연동 가능하도록 확장 여지

---

## 4. 화면 구조 (하단 탭 내비게이션)

| 탭 | 내용 |
|---|---|
| **Home** | 다음 게더링 카드, 추천 간증, 내 신청 상태, 오늘의 언어 훈련 바로가기 |
| **Countries** | 8개국 카드 → 국가 상세(①) → 나라방(②) / 기도(⑧) / 후기(⑥) / 신청(⑦) |
| **Train** | 언어 훈련(③A), 선교 교육(③B), 수료 현황(③C) |
| **Community** | 내 나라방, 팀(④), 기도 제목 전체(⑧), 간증 전체(⑥), 후원 사연(⑨) |
| **My** | 프로필, 내 신청·연장, 준비물 체크리스트, 출석 기록, 언어 설정(EN/KO) |
| **Admin** | (관리자만) 신청 승인, 후기 승인/추천, 수료 승인, 콘텐츠 관리, 게더링·출석, 설정 |

---

## 5. 데이터베이스 (Supabase) — 주요 테이블

```
profiles            id(=auth.uid), name, email, phone, school, role(member|graduate|admin), lang, created_at
countries           id, code, name_en, name_ko, is_sensitive, intro, ministry, daily_life, language, housing, sort_order, is_active
country_photos      id, country_id, url, caption, sort_order
room_members        user_id, country_id, joined_at          -- 나라방 참여(자유)
messages            id, country_id, user_id, body, created_at, deleted
applications        id, user_id, country_id, start_date, duration_text, expected_return, contact, motivation,
                    status(submitted|approved|rejected|preparing|on_field|returned), admin_note, created_at, updated_at
application_extensions  id, application_id, new_return_date, reason, status(pending|approved|rejected), created_at
gospel_messages     id, title, base_text, sort_order, is_active
gospel_sentences    id, message_id, country_id, seq, source_text, local_text, pronunciation, audio_url
language_progress   user_id, sentence_id, repeat_count, mastery(0-3), last_practiced
courses             id, title_en, title_ko, video_url, description, sort_order, required
course_feedback     id, user_id, course_id, feedback, admin_comment, completed_at
graduation_requests id, user_id, status, created_at
teams               id, name, country_id, description
team_members        team_id, user_id, role
team_tasks          id, team_id, title, assignee, status, due_date
team_posts          id, team_id, user_id, body, created_at
gatherings          id, date, start_time, end_time, location, title, sermon_notes, sharing_notes
attendance          gathering_id, user_id, checked_at
testimonies         id, user_id, country_id, title, body, photos[], status(pending|approved|rejected), featured, created_at
prayers             id, user_id, country_id, body, answered, created_at
prayer_reactions    prayer_id, user_id          -- 1인 1회
checklist_items     id, country_id, label_en, label_ko, sort_order
checklist_progress  user_id, item_id, checked
support_stories     id, user_id, title, story, link_url, status(pending|approved|rejected), created_at
app_settings        key, value                  -- require_graduation_to_apply, sensitive_photo_block 등
```

**RLS 원칙**
- 본인 데이터는 본인만 수정, 관리자는 전체
- `testimonies`, `support_stories`는 `approved`만 공개 조회 (작성자·관리자는 본인 `pending` 조회 가능)
- `applications`는 본인 + 관리자만 조회
- 관리자 판별은 `profiles.role = 'admin'` 기반 헬퍼 함수 사용

---

## 6. 보안·선교지 보호 원칙 (전 기능 공통)

- 민감 국가 콘텐츠에는 항상 보안 안내 표시
- 후기·후원 사연은 승인 후 공개
- 현지 성도 실명·얼굴·정확한 장소 금지 안내
- 민감 국가 사진 업로드 제한 옵션
- 신청서 개인정보는 본인·관리자만 열람

---

## 7. 개발 순서 (11/20 역산)

| 단계 | 기간(목표) | 내용 |
|---|---|---|
| 1 | ~10/22 | Supabase 스키마·RLS·시드, 로그인/회원가입, 등급, i18n 뼈대, 탭 내비게이션 |
| 2 | ~10/29 | ① 나라별 정보, ② 나라방 채팅, ⑦ 신청·상태·연장, 관리자 승인 화면 |
| 3 | ~11/5 | ③ 언어 훈련(무한 반복·집중 훈련), 선교 교육·피드백·수료 |
| 4 | ~11/12 | ⑤ 게더링·출석, ⑥ 후기(승인제), ⑧ 기도, ⑨ 체크리스트·후원, ④ 팀 |
| 5 | ~11/18 | 실제 콘텐츠 입력(사진·메시지 번역·강의), 전체 테스트, PWA 설치 테스트 |
| 발족식 | 11/20 | 현장 QR로 가입 → 나라 둘러보기 → 신청 시연 + 메타버스 예고편 영상 |

---

## 8. 범위 외 / 추후 결정

- 🔜 **2단계: 메타버스 공간** (아바타로 나라별 부스 이동) — 발족식에서 예고편만 공개
- ❓ 팀 구성 방식 (자동 vs 관리자 지정)
- 🔜 현지 선교지 담당자 계정
- 🔜 앱 내 후원 결제
- 🔜 국가 페이지 추가 항목, 선교지 국가 추가

---

## 9. Claude Code에게 요청할 첫 작업

1. 위 스키마 기준 `.sql` 파일(스키마 / RLS / 8개국 시드 / 관리자 지정) 작성
2. 단일 `index.html`로 1단계(로그인·등급·i18n·탭 구조) 구현
3. 이후 단계별로 기능 추가, 각 단계마다 완전한 파일로 전달
