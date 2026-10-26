# SVM 스토어 앱 (Google Play · App Store)

웹앱(`app/index.html`)을 [Capacitor](https://capacitorjs.com)로 감싼 안드로이드·아이폰 앱입니다.
화면과 기능은 웹앱과 같고, 스토어 앱에서만 아래가 더해집니다.

- **푸시 알림** (아이폰 APNs 직접 · 안드로이드 FCM): 신청 승인, 보험 확인, 팀 추가, 리더 답글, 새 신고(관리자) 등. 알림을 누르면 해당 화면이 열립니다.
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

## 1. 한 번만: 푸시 알림 열쇠 (아이폰은 APNs 직접, 안드로이드는 FCM 키)

**아이폰 — Firebase 필요 없음**
1. [developer.apple.com](https://developer.apple.com/account/resources/authkeys/list) → Keys → **+** → *Apple Push Notifications service (APNs)* 체크 → `AuthKey_XXXXXXXXXX.p8` 다운로드 (한 번만 받을 수 있으니 안전하게 보관). 화면의 **Key ID** 를 적어 두세요.
2. [Membership details](https://developer.apple.com/account) 에서 **Team ID** 를 적어 두세요.
3. 앱 ID `com.imamerica.svm` 에 *Push Notifications* 가 켜져 있어야 합니다 (Xcode 의 Signing & Capabilities 에서 자동으로 켜집니다).

**안드로이드 — 구글 푸시(FCM)는 구조상 피할 수 없지만 Firebase 화면을 쓸 일은 이것뿐**
1. [console.firebase.google.com](https://console.firebase.google.com) 에서 프로젝트 하나(`SVM`)를 만들고 Android 앱 `com.imamerica.svm` 을 등록 → `google-services.json` 을 `svm/mobile/android/app/google-services.json` 에 넣습니다 (저장소에는 올라가지 않음).
2. 프로젝트 설정 → **서비스 계정** → *새 비공개 키 생성* → JSON (서버가 푸시를 보낼 때만 씁니다).
3. 안드로이드 푸시를 아직 안 쓸 거라면 이 칸은 건너뛰어도 됩니다. 아이폰만 먼저 켤 수 있어요.

> 비밀 파일(`.p8`, 서비스 계정 JSON, `google-services.json`)은 **절대 저장소에 넣지 마세요.** 아래 2단계에서 Supabase 비밀값으로만 넣습니다.

## 2. 한 번만: Supabase (푸시 보내는 서버 함수)

1. **SQL Editor** → `sql/01_스키마.sql` → `sql/02_RLS.sql` 실행 (`device_tokens` 테이블과 등록 함수)
2. **Edge Functions** → *Deploy a new function* → *Via Editor* → 이름 `push`
   → `supabase/functions/push/index.ts` 내용을 그대로 붙여 넣고 Deploy
   → 함수 설정에서 **Verify JWT 끄기** (웹훅 비밀값으로 따로 확인합니다)
3. **Edge Functions → Secrets** 에 추가
   - `PUSH_WEBHOOK_SECRET` : 아무 긴 문자열 (비밀번호 생성기로 40자)
   - 아이폰: `APNS_KEY` (.p8 파일 내용 **전체**, `-----BEGIN PRIVATE KEY-----` 포함) · `APNS_KEY_ID` · `APNS_TEAM_ID` · `APNS_TOPIC` (생략하면 `com.imamerica.svm`)
   - 안드로이드: `FCM_SERVICE_ACCOUNT` (서비스 계정 JSON 전체)
4. **Database → Webhooks** → *Create a new hook*
   - Table: `notifications`, Events: **Insert**
   - Type: **Supabase Edge Functions** → `push`, Method POST
   - HTTP Headers 에 `x-webhook-secret` = 3번의 `PUSH_WEBHOOK_SECRET` 값

이제 앱 안 알림이 생길 때마다 그 회원의 폰으로 푸시가 갑니다. 함수 로그(Edge Functions → push → Logs)에서 `["sent"]` 를 확인할 수 있습니다. 로그 읽는 법:
- `no devices` : 연결은 맞고 아직 등록된 폰이 없음 (정상)
- `ios: APNS secrets missing` / `android: FCM_SERVICE_ACCOUNT missing` : 해당 비밀값을 넣지 않음
- `failed: ios 403 InvalidProviderToken` : Key ID / Team ID / .p8 가 서로 안 맞음
- `failed: ios 400 BadDeviceToken` : 토큰이 이 앱(번들 ID)의 것이 아니거나 만료
- `failed: android 404` : 앱을 지웠거나 만료된 토큰 (자동으로 정리됨)

## 3. 아이폰 앱 (Xcode)

```bash
cd svm/mobile
npm run ios        # 웹 파일 복사 + 동기화 + Xcode 열기
```

1. (이제 `GoogleService-Info.plist` 는 필요 없습니다 — 아이폰은 Firebase 없이 APNs 로 직접 받습니다)
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
