# 자동 테스트

기능을 더할 때마다 예전 기능이 깨지지 않았는지 사람이 일일이 눌러 보지 않아도 되게 하는 테스트입니다.
**실제 운영 데이터베이스에는 아무것도 하지 않습니다.**

| 테스트 | 무엇을 보나 | 실행 |
|---|---|---|
| `tests/sql/` | `sql/01~14` 를 **진짜로 새 Postgres 에 올려서**, 가입·신청·승인·체크인·비상 요청·리더 방·컨퍼런스 등록·개선 제안·기도 짝·계정 삭제 등에서 **누가 무엇을 볼 수 있고 할 수 있는지**(권한 규칙)와 알림이 맞는지 | `bash tests/sql/run.sh` |
| `tests/e2e/` | 데모 모드 앱을 브라우저로 열어 가입 → 신청 → 승인 → 출발 카드 → 일정표 → 비상 버튼 → 채팅 → 개선 제안 → 컨퍼런스 접수, 학생 권한(관리 메뉴·리더 방이 안 보임), 컴퓨터 화면 배치까지 | `node tests/e2e/run.js` |

- SQL 테스트는 Postgres 가 있는 컴퓨터(리눅스/맥)에서 돌아갑니다. Supabase 대신 쓰는 최소한의 흉내(`tests/sql/stubs.sql`)가 들어 있어요.
- 화면 테스트는 `playwright` 가 필요합니다 (`npm i -D playwright && npx playwright install chromium`).
- 두 테스트 모두 GitHub 에서 `main` 에 올릴 때와 PR 을 만들 때 자동으로 돕니다 (`.github/workflows/test.yml`).
- 새 기능을 만들면 `tests/sql/scenarios.sql` 에 "누가 되고 누가 안 되는지" 줄을 몇 개 더하세요. `select test.ok(조건, '설명')` 으로 통과해야 하는 것, `select test.throws('SQL', '설명')` 으로 거절되어야 하는 것을 적습니다.

**한계**: 데모 데이터와 가짜 Supabase 로 하는 시험입니다. 실제 Supabase 의 이메일 인증, 저장소(사진 업로드), 푸시 알림, 폰 기기 동작은 시험하지 못합니다. 그건 `tests/REHEARSAL.md` 의 리허설로 확인합니다.
