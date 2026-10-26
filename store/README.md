# 스토어 등록 자료 (Google Play · App Store)

앱 이름 **SVM** · 번들/패키지 ID `com.imamerica.svm` · 게시자 **IM America Group Corp**

| 파일 | 내용 |
|---|---|
| [`listing.md`](listing.md) | 스토어 소개 글 — 영어·한국어 (이름, 부제, 짧은/긴 설명, 키워드, 업데이트 내용, 분류) |
| [`privacy-answers.md`](privacy-answers.md) | Google **데이터 보안** 양식 · Apple **개인정보 보호 영양 표시** 답변, 연령 등급 |
| [`review-notes.md`](review-notes.md) | 심사 메모(영어, 그대로 붙여 넣기) · 심사용 계정 만드는 법 · 심사에서 자주 걸리는 점 점검 |
| `screenshots/` | 스크린샷: `ios/`(1290×2796) · `android/`(1080×1920), 각각 `en/` `ko/` 8장 |

스크린샷은 `tools/store_screenshots.js` 로 다시 만들 수 있습니다 (앱 화면을 바꾼 뒤에 다시 찍으세요).

## 올리는 순서

1. **심사용 계정** 만들기 → `review-notes.md` 의 SQL 로 승인된 신청서까지 넣어 두기
2. **Google Play Console**: 앱 만들기 → 스토어 등록정보(`listing.md`, 스크린샷 `android/`) → 앱 콘텐츠(개인정보처리방침 URL, 데이터 보안, 콘텐츠 등급, 광고 없음, 앱 액세스 = 심사용 계정) → `.aab` 업로드 (내부 테스트 → 프로덕션)
3. **App Store Connect**: 새 앱 → 앱 정보(`listing.md`) → 스크린샷 `ios/` → 앱 개인정보 보호(`privacy-answers.md`) → 연령 등급 → 심사 메모/계정(`review-notes.md`) → Xcode 에서 Archive 업로드 → 심사 제출
4. 빌드·서명은 `mobile/README.md` 를 따르세요.

## 주소 (스토어 양식에 그대로)

| 항목 | 주소 |
|---|---|
| 마케팅/지원 | https://koreayjk.github.io/svm/ |
| 개인정보처리방침 | https://koreayjk.github.io/svm/privacy/ |
| 이용약관 | https://koreayjk.github.io/svm/terms/ |
| 계정 삭제 안내 (Google 필수) | https://koreayjk.github.io/svm/privacy/#delete |
| 웹 앱 | https://koreayjk.github.io/svm/app/ |

지원 이메일은 아직 정해지지 않았습니다 — 두 스토어 모두 **연락 가능한 이메일**을 요구하니 정해서 넣어 주세요.
