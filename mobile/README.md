# SVM 스토어 앱 (Google Play · App Store)

웹앱(`app/index.html`)을 [Capacitor](https://capacitorjs.com)로 감싼 안드로이드·아이폰 앱입니다.
화면과 기능은 웹앱과 같고, 스토어 앱에서만 아래가 더해집니다.

- **푸시 알림** (Firebase Cloud Messaging): 신청 승인, 보험 확인, 팀 추가, 리더 답글, 새 신고(관리자) 등. 알림을 누르면 해당 화면이 열립니다.
- **앱 아이콘 숫자**: 안 읽은 알림 + 안 읽은 채팅
- 안드로이드 뒤로 가기 버튼, 폰 음성 엔진으로 읽어 주기(언어 훈련)

| 항목 | 값 |
|---|---|
| 앱 ID (번들 ID) | `com.imamerica.svm` (스토어에 올린 뒤에는 바꿀 수 없음) |
| 앱 이름 | SVM |
| 배포 회사 | IM America Group Corp |
| 버전 | 1.0 (빌드 1) |

---

## 0. 한 번만: Mac 준비

1. **Xcode** (App Store에서 설치) → 한 번 열어서 추가 구성요소 설치
2. **Android Studio** ([developer.android.com/studio](https://developer.android.com/studio))
3. **Node.js 22** ([nodejs.org](https://nodejs.org)) → 터미널에서 `node -v` 로 확인
4. 저장소 받기
   ```bash
   git clone https://github.com/koreayjk/svm.git
   cd svm/mobile
   npm install
   ```

## 1. 한 번만: Firebase (푸시 알림)

1. [console.firebase.google.com](https://console.firebase.google.com) → **프로젝트 추가** → 이름 `SVM` (Google 애널리틱스는 꺼도 됨)
2. **Android 앱 추가** → 패키지 이름 `com.imamerica.svm` → `google-services.json` 다운로드
   → `svm/mobile/android/app/google-services.json` 에 넣기
3. **iOS 앱 추가** → 번들 ID `com.imamerica.svm` → `GoogleService-Info.plist` 다운로드
   → 나중에 Xcode에서 `App/App` 폴더에 끌어다 놓기 (아래 3단계)
4. **APNs 키 연결 (아이폰 푸시)**
   - [developer.apple.com](https://developer.apple.com/account/resources/authkeys/list) → Keys → **+** → *Apple Push Notifications service (APNs)* 체크 → `.p8` 파일 다운로드 (한 번만 받을 수 있으니 안전하게 보관)
   - Firebase → 프로젝트 설정 → **클라우드 메시징** → Apple 앱 구성 → APNs 인증 키 업로드 (키 ID, 팀 ID 입력)
5. **서비스 계정 키 (서버에서 푸시 보내기용)**
   - Firebase → 프로젝트 설정 → **서비스 계정** → *새 비공개 키 생성* → JSON 파일
   - 이 파일은 **절대 저장소에 넣지 마세요.** 2단계에서 Supabase 비밀값으로만 넣습니다.

> `google-services.json`, `GoogleService-Info.plist` 는 `.gitignore` 에 있어 저장소에 올라가지 않습니다.

## 2. 한 번만: Supabase (푸시 보내는 서버 함수)

1. **SQL Editor** → `sql/01_스키마.sql` → `sql/02_RLS.sql` 실행 (`device_tokens` 테이블과 등록 함수)
2. **Edge Functions** → *Deploy a new function* → *Via Editor* → 이름 `push`
   → `supabase/functions/push/index.ts` 내용을 그대로 붙여 넣고 Deploy
   → 함수 설정에서 **Verify JWT 끄기** (웹훅 비밀값으로 따로 확인합니다)
3. **Edge Functions → Secrets** 에 두 개 추가
   - `FCM_SERVICE_ACCOUNT` : 1-5에서 받은 JSON 파일 내용 **전체**
   - `PUSH_WEBHOOK_SECRET` : 아무 긴 문자열 (예: 비밀번호 생성기로 40자)
4. **Database → Webhooks** → *Create a new hook*
   - Table: `notifications`, Events: **Insert**
   - Type: **Supabase Edge Functions** → `push`, Method POST
   - HTTP Headers 에 `x-webhook-secret` = 3번의 `PUSH_WEBHOOK_SECRET` 값

이제 앱 안 알림이 생길 때마다 그 회원의 폰으로 푸시가 갑니다. 함수 로그(Edge Functions → push → Logs)에서 `["sent"]` 를 확인할 수 있습니다.

### 번역 함수 (선택)

공유된 글의 '번역' 버튼을 쓰려면 같은 방식으로 함수를 하나 더 올립니다.

1. **Edge Functions** → *Deploy a new function* → *Via Editor* → 이름 `translate` → `supabase/functions/translate/index.ts` 내용 붙여 넣고 Deploy (**Verify JWT 켜 둠** — 로그인한 회원만 부를 수 있어요)
2. **Secrets** 에 `ANTHROPIC_API_KEY` 추가 ([console.anthropic.com](https://console.anthropic.com) 에서 만든 키, 저장소에는 절대 넣지 않기)
3. 요금은 번역한 글자 수만큼만 나오고, 같은 글은 저장해서 다시 번역하지 않으며 회원당 하루 60번으로 막아 둡니다.

## 3. 아이폰 앱 (Xcode)

```bash
cd svm/mobile
npm run ios        # 웹 파일 복사 + 동기화 + Xcode 열기
```

1. 처음 한 번: `GoogleService-Info.plist` 를 왼쪽 `App/App` 폴더로 끌어다 놓기 → *Copy items if needed*, Target **App** 체크
2. **App** 타깃 → *Signing & Capabilities*
   - Team: **IM America Group Corp** 선택, *Automatically manage signing*
   - **Push Notifications** 과 **Background Modes → Remote notifications** 가 보이는지 확인 (없으면 *+ Capability* 로 추가)
3. 아이폰을 연결하고 ▶︎ 실행 → 로그인 → 알림 허용 → 관리자 계정에서 신청 승인 등을 해 보면 푸시가 옵니다
4. 제출: 메뉴 *Product → Archive* → *Distribute App → App Store Connect → Upload*

## 4. 안드로이드 앱 (Android Studio)

```bash
cd svm/mobile
npm run android    # 웹 파일 복사 + 동기화 + Android Studio 열기
```

1. 폰을 USB로 연결(개발자 옵션 → USB 디버깅)하고 ▶︎ 실행해서 확인
2. 제출용: 메뉴 *Build → Generate Signed App Bundle / APK* → **Android App Bundle**
   - 처음 한 번 **새 키스토어 만들기** → 파일과 비밀번호를 **안전한 곳 두 군데 이상에 보관** (잃어버리면 업데이트를 못 올립니다. Play 앱 서명을 켜면 업로드 키만 다시 발급 가능)
   - `release` 선택 → 만들어진 `.aab` 를 Play Console → 프로덕션(또는 내부 테스트) → 새 버전에 업로드

## 업데이트할 때마다

웹앱(`app/index.html`)을 고친 뒤:

```bash
cd svm/mobile
npm run sync       # app/ 의 최신 파일을 앱에 넣음
```

- 아이폰: Xcode에서 *Version*(1.0 → 1.1) 또는 *Build*(1 → 2) 올리고 Archive
- 안드로이드: `android/app/build.gradle` 의 `versionCode`(1 → 2)와 `versionName` 올리고 App Bundle 다시 만들기

## 아이콘·시작 화면 다시 만들기

`mobile/assets/` 의 원본(`icon-only.png` 1024×1024, `icon-foreground.png`, `icon-background.png`, `splash.png`, `splash-dark.png`)을 바꾼 뒤:

```bash
npm run assets
```

## 폴더 구성

| 경로 | 내용 |
|---|---|
| `capacitor.config.json` | 앱 ID·이름·플러그인 설정 |
| `www/` | `npm run web` 이 만드는 웹 파일 (저장소에 올리지 않음) |
| `android/`, `ios/` | 네이티브 프로젝트 (Android Studio / Xcode 로 열기) |
| `assets/` | 아이콘·시작 화면 원본 |
| `../tools/build_mobile_www.py` | `app/index.html` → `www/` (라이브러리 포함, 경로 정리) |
| `../supabase/functions/push/` | 푸시 보내는 서버 함수 |
