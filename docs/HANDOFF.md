# SVM 인수인계 (2026-11-01 기준)

새 세션에서 이 파일을 먼저 읽으세요. 사용자는 한국어로 말하고, 답도 한국어로 합니다.

## 1. 프로젝트
- 저장소 `koreayjk/svm` — SVM(Student Volunteer Movement, Bryan/College Station TX) 홈페이지 + 웹앱 + 스토어 앱.
- GitHub Pages: `/`(홈) · `/conference/` · `/host/` · `/app/`(앱) · `/privacy/` · `/terms/`
- 색: 남색 `#0D1B3A` / 주황 `#F26722`. 한국어·영어 둘 다.
- 앱은 단일 파일 `app/index.html`(약 8,000줄). 데모(`?demo`, `?demo&confday`)와 Supabase 두 모드. 캐시 버전은 `app/sw.js`의 `VERSION`(현재 `svm-v84`) — 앱을 고치면 올립니다.
- 스토어 앱: `mobile/`(Capacitor). 스토어 자료: `store/`.
- 컨퍼런스: 2026-11-20 (금) 오후 6시, Country Fellowship Church, 408 E 24th St, Bryan TX 77803. 두 교회는 같은 건물.

## 2. 작업 방식 (지켜야 할 것)
- 개발 브랜치 `claude/new-session-kth0j2`. PR은 **사용자가 "합쳐줘"라고 할 때만** 만들고 합칩니다(squash).
- squash 뒤 브랜치 기록이 어긋납니다. force-push는 막혀 있으니 `git fetch origin claude/new-session-kth0j2 && git merge -s ours origin/claude/new-session-kth0j2` 후 일반 push 합니다. 작업 전 `git fetch origin main && git reset --hard origin/main`.
- 커밋 끝에 Co-Authored-By / Claude-Session 줄, PR 끝에 Generated with Claude Code 줄. 커밋·PR에 모델 이름 쓰지 않기.
- 앱을 고친 뒤: `python3 tools/build_mobile_www.py` → `python3 tools/build_demo_artifact.py <출력.html>` → Artifact 재게시(데모 URL 아래). 홈페이지는 `tools/build_site_artifact.py`.
- 비밀값은 저장소에 절대 넣지 않기(service_role, Firebase 서비스계정, APNs .p8, keystore). 프런트에는 anon key만.
- 현지 성도의 얼굴·실명·정확한 위치 금지. 민감 국가는 인원수만 보여 주고 이름 목록·입력 중 표시·읽은 사람 이름은 숨김. 리더 방은 학생에게 안 보임(화면·라우트·RLS).
- 테스트: `bash tests/sql/run.sh`(SQL 122개), `node tests/e2e/run.js`(앱 40개). 고친 뒤 둘 다 통과시키기. Playwright에서 hover 버튼은 `dispatchEvent('click')`.
- `pkill -f` 패턴 주의(내 셸이 죽음).

## 3. 현재 상태 (끝난 것)
- main에 모두 합쳐짐(PR #74까지). 데모 artifact: https://claude.ai/artifact/1wApJxwSfNcVXnnFrB9hPP
- 채팅 기본(답장·이모지·수정/삭제·사진) + 고급(@멘션·글 고정·검색·읽음 표시·입력 중 표시), 채팅 상위 메뉴, 리더 방(나라별·전체), 멤버 패널, 개선 제안 게시판, 컨퍼런스 접수, 비상 버튼, 여정 일정표, 기도 짝, 데스크톱 레이아웃.
- 폰 글자 크기 한 단계 축소, 폰 하단 메뉴 = 4개 + **더보기**(관리자: 홈·선교지·채팅·관리·더보기 / 그 외: 홈·선교지·훈련·채팅·더보기). 컴퓨터는 왼쪽 사이드바 7개.
- 스토어 스크린샷 새로 생성(`store/screenshots/ios|android/en|ko/`, 9장). `node tools/store_screenshots.js http://localhost:8811 store/screenshots`(먼저 `python3 -m http.server 8811`).
- Supabase 프로젝트 `svm` (id `uafdrygbaloqffhwcebc`, us-west-2). **다른 프로젝트(aim, tcs, imcms 등)는 건드리지 않기.** SQL 01~16 모두 적용 확인됨. `push` 함수 v2 배포됨(최신 코드). `.claude/settings.json`에 `mcp__Supabase__execute_sql` 자동 허용 설정(어느 프로젝트에도 적용되니 svm만 쓰기).

## 4. 남은 일 — 푸시 알림 (가장 급함)
2026-11-01 점검 결과:
- ❌ **DB 웹훅 없음** (notifications INSERT → `push`). `pg_net`도 아직 미설치. Database → Webhooks 에서 만들기(테이블 `notifications`, Insert, Supabase Edge Function `push`, POST, 헤더 `x-webhook-secret` = `PUSH_WEBHOOK_SECRET`).
- ❌ `push` 함수 **Verify JWT가 켜져 있음** → 끄기(웹훅 비밀값으로 따로 확인함).
- ❓ 시크릿 미확인(커넥터로 목록 못 봄): `PUSH_WEBHOOK_SECRET`, `APNS_KEY`(.p8 전체), `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC`(기본 `com.imamerica.svm`), `FCM_SERVICE_ACCOUNT`. 사용자가 대시보드(Edge Functions → Secrets → Add or replace secrets)에서 직접 넣음. 채팅에 붙여 넣게 하지 말 것.
- ❌ `device_tokens` 0개 — 스토어용 앱을 폰에 설치·로그인·알림 허용해야 생김(웹/시뮬레이터 불가).
- iOS: Xcode에서 Push Notifications 권한 확인. Android: `mobile/android/app/google-services.json` 필요(저장소에 올리지 않음).
- 테스트: 계정 둘로 답장/@멘션 → 잠긴 폰에 푸시 확인. 안 오면 Edge Functions → push → Logs(`["sent"]`), 403이면 웹훅 비밀값 불일치.
- 푸시가 가는 채팅: 내 글 답장, 나를 멘션, 선교지 대화·리더방 새 글. 국가 방의 모든 새 글에는 푸시 없음(의도).
- 자세한 순서: `mobile/README.md` 1~2단계.

## 5. 남은 일 — 스토어 출시
1. 개발자 계정(Apple/Google) 준비, 빌드 업로드(`mobile/README.md`). 사용자는 스토어 등록 경험 있음.
2. 심사 정보: `store/listing.md`, `store/privacy-answers.md`(위치는 선택), `store/review-notes.md`(on_field 데모 계정), 스크린샷, `privacy/index.html`.
3. 출시 전 리허설: `tests/REHEARSAL.md`.

## 6. 남은 일 — 11/20 컨퍼런스 전
- 컨퍼런스 일정표(run-of-show)를 이벤트 설명에 입력(앱 현장 모드가 사용).
- 사용자 2명 이상으로 현장 접수 리허설(관리자 → 마이 → 컨퍼런스 접수).
- 등록은 관리자 화면 신청 목록과 컨퍼런스 접수에서 확인(단체 이름·인원 수 포함).

## 7. 아이디어 (사용자가 아직 안 고른 것)
- 국가 방 새 글 전체 푸시(옵션으로), 더보기 시트에 개선 제안·알림 바로가기, 사진 EXIF 위치 자동 제거 점검, 홈 상단 "읽지 않은 채팅" 요약.

## 8. 주요 파일 지도
- `app/index.html` 채팅 모듈(`createChat`, `ck*`), 탭(`TABS`, `SUB_TAB`, `islandHTML`, `overflowTabs`), 뷰(`VIEWS.*`, `BINDERS.*`), 번역(EN/KO 블록 두 군데: `tab_*` 키 근처)
- `sql/01~16_*.sql` — 전부 재실행 가능. 새 기능은 17번부터.
- `supabase/functions/push/index.ts` — 푸시 문구(`TEXT`)·`bodyFor()`. 알림 종류를 추가하면 여기에도 문구 추가 후 함수 재배포.
- `tests/sql/scenarios.sql`, `tests/e2e/run.js`, `.github/workflows/test.yml`
- `tools/` 빌드·스크린샷 스크립트
