# SVM — Student Volunteer Movement App

브라이언 컬리지 스테이션 학생자원운동(SVM) 선교 지원 플랫폼.
명세서: [`docs/SVM_App_Spec.md`](docs/SVM_App_Spec.md) · 목표: 2026-11-20 발족식

## 현재 상태 — 1단계 완료

| 항목 | 상태 |
|---|---|
| Supabase 스키마 (전체 9개 기능 테이블) · RLS · 8개국 시드 · 관리자 지정 SQL | ✅ |
| 이메일 로그인 / 회원가입 / 비밀번호 재설정 | ✅ |
| 회원 등급 (member · graduate · admin) + 배지 | ✅ |
| i18n (EN / 한국어 토글, 프로필에 저장) | ✅ |
| 하단 탭: Home · Countries · Train · Community · My · Admin(관리자만) | ✅ |
| 홈: 다음 게더링 카드, SVM 핵심 컨셉 4가지 | ✅ |
| 나라 목록·상세 (5개 섹션, 민감 국가 보안 배너) | ✅ (나라방·신청 버튼은 2단계) |
| 관리자: 회원 등급 변경, `require_graduation_to_apply` / 민감국가 사진 차단 설정, 국가 민감도·노출 on/off | ✅ |
| PWA (manifest + service worker, 홈 화면 설치) | ✅ |
| 2~4단계 기능 | "Phase N" 카드로 자리만 표시 |

## 파일 구조

```
index.html             앱 전체 (단일 파일, Vanilla JS)
manifest.webmanifest   PWA 매니페스트
sw.js                  서비스 워커 (앱 셸 캐시)
icons/                 앱 아이콘
sql/01_스키마.sql       테이블 · 트리거
sql/02_RLS.sql          헬퍼 함수 · RLS 정책 · Realtime · Storage 버킷
sql/03_국가_시드.sql     8개국 · 기본 설정 · 공통 준비물 · 첫 게더링
sql/04_관리자_지정.sql   관리자 지정
```

## 설치 순서

### 1. Supabase 프로젝트
1. [supabase.com](https://supabase.com) 에서 새 프로젝트 생성
2. **SQL Editor** 에서 순서대로 실행: `01_스키마.sql` → `02_RLS.sql` → `03_국가_시드.sql`
   (모두 여러 번 실행해도 안전합니다)
3. **Authentication → URL Configuration**
   - Site URL: `https://<github-아이디>.github.io/svm/`
   - Redirect URLs 에도 같은 주소 추가 (이메일 인증·비밀번호 재설정 링크용)

### 2. 앱 설정
`index.html` 상단 `CONFIG` 에 **Project Settings → API** 의 값을 넣습니다.
```js
const CONFIG = {
  SUPABASE_URL: 'https://xxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...',
};
```
anon key 는 공개용 키입니다. 데이터 보호는 RLS 가 담당합니다 (service_role 키는 절대 넣지 마세요).

### 3. GitHub Pages
Repository **Settings → Pages** → Source: `Deploy from a branch`, Branch: `main` / `/ (root)`

### 4. 관리자 지정
1. 배포된 앱에서 관리자 계정으로 회원가입 (이메일 인증 완료)
2. `sql/04_관리자_지정.sql` 의 이메일을 바꿔 SQL Editor 에서 실행
3. 앱 새로고침 → 하단에 **Admin** 탭이 나타남

## 보안 설계 메모 (RLS)

- `profiles.role` 은 트리거로 보호 — 일반 회원은 본인 등급을 바꿀 수 없음
- 후기·후원 사연은 회원이 `status`/`featured` 를 보내도 항상 `pending` 으로 저장
- 신청서는 본인·관리자만 조회, 상태 변경은 관리자만. 상태 변경 이력은 `application_status_history` 에 자동 기록
- `require_graduation_to_apply` 가 켜지면 DB 단에서 수료 회원 외 신청 차단
- 연장 신청은 `on_field` 상태에서만 가능, 승인 시 `expected_return` 자동 갱신
- 수료 요청 승인 시 자동으로 `graduate` 등급 부여
- 셀프 출석 체크는 게더링 시간(America/Chicago, 앞뒤 30분)에만 허용
- 민감 국가 + `sensitive_photo_block` 이면 후기 사진 저장 차단
- 채팅 작성자 이름은 `profile_names` 뷰로만 노출 (이메일·전화번호 비공개)

## 명세 대비 추가한 컬럼/테이블
- `countries.*_ko` (국가 콘텐츠 한국어판), `countries.extra_sections` (관리자 추가 항목)
- `room_members.last_read_at` (안 읽은 메시지), `application_status_history` (신청 타임라인)
- `language_progress.correct_count / wrong_count`, `practice_days` (연속 학습일)
- `testimonies.prayer_id` (응답된 기도 → 간증 연결), `*.reviewed_at`

## 다음 단계 (2단계, ~10/29)
① 나라 사진 갤러리 · ② 나라방 채팅(Realtime) · ⑦ 신청·상태 타임라인·연장 · 관리자 승인 화면
