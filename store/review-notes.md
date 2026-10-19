# 심사 메모와 심사용 계정

## 1. 심사용 계정 만들기

1. 앱(또는 웹 앱 https://koreayjk.github.io/svm/app/)에서 새 계정 가입: 예) `review@` 로 시작하는 본인 도메인 이메일, 비밀번호는 심사 때만 쓸 새 값.
   - Supabase **Authentication → Providers → Email** 에서 *Confirm email* 이 켜져 있으면, 가입 후 **Authentication → Users** 에서 그 사용자를 열어 이메일을 직접 확인 처리하세요 (심사자가 메일 인증을 못 받습니다).
2. **SQL Editor** 에서 아래를 실행해 신청서를 승인 상태로 만들어 둡니다 (이메일만 바꾸세요). 그러면 출발 준비 카드·보험·알림이 모두 보입니다.

```sql
insert into public.applications (user_id, country_id, track, start_date, expected_return, motivation, status)
select p.id, c.id, 'short', current_date + 21, current_date + 35, 'App review account', 'preparing'
  from public.profiles p, public.countries c
 where p.email = 'review@example.com' and c.code = 'KR' and c.is_active
   and not exists (select 1 from public.applications a where a.user_id = p.id);
```

3. 계정 정보를 양식에 입력: Apple *Sign-in information*, Google *앱 액세스*.
4. 심사가 끝난 뒤 이 계정은 앱에서 삭제하세요 (마이 → 계정 삭제).

## 2. 심사 메모 (Notes for Review — 영어, 그대로 붙여 넣기)

```
SVM is the app of the Student Volunteer Movement, a church-based group in Bryan–College Station, Texas. It trains students for short-term mission trips and helps them prepare, check in while away, and share testimonies afterward. Publisher: IM America Group Corp.

Demo account: <email> / <password>
This account has an approved application, so you can see the preparation checklist, travel insurance upload, notifications and news feed.

Account deletion: My tab → "Delete account" (bottom). Deletes the profile and all data immediately. Also described at https://koreayjk.github.io/svm/privacy/#delete

User-generated content: members can post messages, prayer requests and testimonies. Safeguards: terms accepted at sign-up, Report and Block on every item from other users (the "…" button), admin moderation of reports, and blocked users are hidden. Content from sensitive countries is limited (counts only, photo upload restrictions).

No in-app purchases. No ads. No third-party tracking. There is no donation or payment flow inside the iOS/Android apps.
Login is email + password only (no third-party sign-in).
Notifications are optional and only used for the member's own updates (application status, replies, safety check-ins).
Travel insurance upload is a document upload for the member's own trip; it is private to the member, their country leader and admins.
```

## 3. 심사에서 자주 걸리는 점 — 미리 점검

| 항목 | 상태 |
|---|---|
| 개인정보처리방침 링크 (앱 안 + 스토어) | ✔ 마이 화면 + 가입 화면 |
| 계정 삭제 (앱 안 + Google 웹 URL) | ✔ |
| 신고·차단·약관 동의 (UGC) | ✔ |
| 앱 내 결제 / 외부 결제 유도 | 없음 (후원 링크는 스토어 앱에서 숨김) |
| 푸시 알림 권한 문구 | 알림은 앱 안에서 ‘허용’을 눌러야 요청됨 |
| 최소 기능 (웹사이트 껍데기 느낌, 4.2) | 푸시·배지·뒤로가기·기기 음성 등 앱 전용 기능 포함. 설명에 앱만의 기능을 강조 |
| 심사 계정이 실제로 로그인 되는지 | 제출 직전에 직접 로그인해 확인 |
| 스크린샷에 실제 사람 얼굴·실명 | 없음 (데모 이름 사용) |
| 종교 단체 앱 | 문제 없음. 다만 설명에서 ‘선교’의 내용이 분명하게 보이게 (이미 반영) |

## 4. 거절됐을 때

거절 사유는 대부분 (a) 심사 계정 로그인 실패, (b) 설명과 앱 화면 불일치, (c) 개인정보 답변 누락입니다. 사유를 이 대화에 붙여 넣어 주세요. 고쳐서 다시 올릴 수 있도록 도와드립니다.
