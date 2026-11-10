# SVM 인수인계 (2026-11-06 기준)

새 세션에서 이 파일을 먼저 읽으세요. 사용자는 한국어로 말하고, 답도 한국어로 합니다.

## 1. 프로젝트
- 저장소 `koreayjk/svm` — SVM(Student Volunteer Movement, Bryan/College Station TX) 홈페이지 + 웹앱 + 스토어 앱.
- GitHub Pages: `/`(홈) · `/conference/` · `/host/` · `/app/`(앱) · `/privacy/` · `/terms/`
- 색: 남색 `#0D1B3A` / 주황 `#F26722`. 한국어·영어 둘 다.
- 앱은 단일 파일 `app/index.html`. 데모(`?demo`, `?demo&confday`)와 Supabase 두 모드. 캐시 버전은 `app/sw.js`의 `VERSION`(현재 `svm-v85`) — 앱을 고치면 올립니다.
- 스토어 앱: `mobile/`(Capacitor). 스토어 자료: `store/`.
- 컨퍼런스: 2026-11-20 (금) 오후 6시, Country Fellowship Church, 408 E 24th St, Bryan TX 77803.

## 2. 작업 방식
- 개발 브랜치 `claude/new-session-kth0j2`. PR은 **사용자가 "합쳐줘"라고 할 때만** 합칩니다(squash).
- squash 뒤 브랜치 기록이 어긋납니다. force-push는 막혀 있으니 `git fetch origin main && git reset --hard origin/main` 후 작업하고, push 전에 `git fetch origin claude/new-session-kth0j2 && git merge -s ours origin/claude/new-session-kth0j2` 하면 일반 push가 됩니다. (reset 하면 아직 안 합친 커밋이 사라지니 주의.)
- 커밋 끝에 Co-Authored-By / Claude-Session 줄, PR 끝에 Generated with Claude Code 줄. 커밋·PR에 모델 이름 쓰지 않기.
- 앱을 고친 뒤: `python3 tools/build_mobile_www.py` → `python3 tools/build_demo_artifact.py <출력.html>` → Artifact 재게시(데모: https://claude.ai/artifact/1wApJxwSfNcVXnnFrB9hPP).
- 비밀값은 저장소에 절대 넣지 않기. 프런트에는 anon key만. 시크릿은 사용자가 대시보드에 직접 입력.
- 현지 성도의 얼굴·실명·정확한 위치 금지. 민감 국가는 인원수만. 리더 방은 학생에게 안 보임.
- 테스트: `bash tests/sql/run.sh`(SQL), `node tests/e2e/run.js`(앱). Playwright에서 hover 버튼은 `dispatchEvent('click')`.
- `pkill -f` 패턴 주의.

## 3. 현재 상태
- 채팅 전체(답장·이모지·수정/삭제·사진·멘션·고정·검색·읽음·입력 중), 리더 방, 개선 제안, 컨퍼런스 접수, 비상 버튼, 여정 일정표, 기도 짝, 데스크톱 레이아웃.
- 폰 하단 메뉴 = 4개 + 더보기, 폰 글자 한 단계 축소, 채팅 입력창 하단 고정 버그 수정(#75).
- 스토어 스크린샷 재생성(#76). `node tools/store_screenshots.js http://localhost:8811 store/screenshots`(먼저 `python3 -m http.server 8811`).
- Supabase 프로젝트 `svm` (id `uafdrygbaloqffhwcebc`). **다른 프로젝트(aim, tcs, imcms 등)는 건드리지 않기.** SQL 01~16 적용됨. **SQL 17(나이대)은 사용자가 아직 실행 전일 수 있음.**
- `push` 함수 v3 배포, Verify JWT 꺼짐, DB 웹훅 `push_on_notification`(notifications INSERT) 생성, `PUSH_WEBHOOK_SECRET` 설정됨(테스트 알림으로 200 `no devices` 확인).
- 나이대 선택 항목(SQL 17 + 가입/마이 폼 + 관리자 통계 "나이대별") 추가 작업 중/완료 — PR 상태 확인.

## 4. 남은 일 — 푸시 알림
- ❓ 애플 키 시크릿 `APNS_KEY`(.p8 전체) · `APNS_KEY_ID` · `APNS_TEAM_ID`, 안드로이드 `FCM_SERVICE_ACCOUNT` — 아직 넣었는지 모름.
- ❌ `device_tokens` 0개: 스토어 빌드를 폰에 설치하고 로그인·알림 허용해야 생김.
- iOS Xcode Push Notifications 권한, Android `mobile/android/app/google-services.json`(저장소에 올리지 않음).
- 테스트: 계정 둘로 답장/@멘션 → 푸시. 로그: Edge Functions → push → Logs, 또는 `net._http_response` 조회.
- 순서: `mobile/README.md` 1~2단계.

## 5. 남은 일 — 스토어 출시
1. Apple/Google 개발자 계정, 빌드 업로드(`mobile/README.md`).
2. 심사 정보: `store/listing.md`, `store/privacy-answers.md`, `store/review-notes.md`, 스크린샷, `privacy/index.html`. 나이대 항목(선택)이 생겼으니 privacy-answers에 반영 확인.
3. 출시 전 리허설: `tests/REHEARSAL.md`.

## 6. 11/20 컨퍼런스 전
- 이벤트 설명에 run-of-show 입력, 현장 접수 리허설.

## 7. 통계 참고
- 미국 선교사 통계(웹 조사): 2010 CSGC 12.7만(세계 40만), 2020 WCD 13.5만. 정확한 수치는 Missio Nexus 데이터 요약, World Christian Database, Barna(The Future of Missions). 나이대별 공개 통계는 못 찾음.

## 8. 파일 지도
- `app/index.html`: 채팅(`createChat`, `ck*`), 탭(`TABS`, `SUB_TAB`, `islandHTML`, `overflowTabs`), 뷰(`VIEWS.*`, `BINDERS.*`), 관리자 통계 `adminStatsHTML`, 번역 EN/KO 블록 두 군데.
- `sql/01~18_*.sql` 재실행 가능. 새 기능은 19번부터.
- `supabase/functions/push/index.ts` — 알림 문구 `TEXT`, `bodyFor()`. 종류 추가 시 함수 재배포.
- `tests/`, `.github/workflows/test.yml`, `tools/`
