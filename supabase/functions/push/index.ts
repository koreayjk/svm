// SVM 푸시 알림 — notifications 테이블에 새 행이 생기면(데이터베이스 웹훅) 그 회원의 폰으로 보냅니다.
// Firebase Cloud Messaging(HTTP v1) 하나로 안드로이드와 아이폰(APNs 키를 Firebase에 등록) 모두 보냅니다.
//
// 필요한 비밀값 (Supabase 대시보드 → Edge Functions → Secrets, 저장소에 절대 넣지 않음)
//   FCM_SERVICE_ACCOUNT  : Firebase 서비스 계정 JSON 전체
//   PUSH_WEBHOOK_SECRET  : 웹훅 요청 헤더 x-webhook-secret 과 같은 임의의 긴 문자열
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY 는 Supabase 가 자동으로 넣어 줍니다.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const TEXT: Record<string, Record<string, string>> = {
  "en": {
    "nt_app": "Your application for {c}: {s}",
    "nt_ext_ok": "Extension approved. New return date: {d}",
    "nt_ext_no": "Your extension request (to {d}) was not approved.",
    "nt_grad_ok": "You are now a graduate. Congratulations!",
    "nt_grad_no": "Your graduation request was not approved yet. Keep training!",
    "nt_testi_ok": "Your testimony “{x}” is now published.",
    "nt_testi_no": "Your testimony “{x}” was not published.",
    "nt_sup_ok": "Your support story “{x}” is now published.",
    "nt_sup_no": "Your support story “{x}” was not published.",
    "nt_reply": "A leader replied to your reflection.",
    "nt_team": "You were added to {x}.",
    "nt_ins_ok": "Your travel insurance was verified.",
    "nt_ins_fix": "Your travel insurance needs changes. Tap to see what HQ said.",
    "nt_report": "New report to review: {k}.",
    "nt_generic": "You have an update.",
    "st_submitted": "Submitted",
    "st_approved": "Approved",
    "st_rejected": "Not approved",
    "st_preparing": "Preparing to go",
    "st_on_field": "On the field",
    "st_returned": "Returned",
    "rp_kind_message": "Chat message",
    "rp_kind_prayer": "Prayer request",
    "rp_kind_testimony": "Testimony",
    "rp_kind_team_post": "Team post",
    "rp_kind_user": "Member",
    "nt_leader_msg": "Your country leader sent you a message.",
    "nt_student_msg": "A student sent you a message.",
    "nt_new_app": "New application for {c}.",
    "nt_dep": "{d} days until departure to {c}. Check your preparation list.",
    "nt_dep_today": "Departure day for {c}. Safe travels.",
    "nt_ins_due": "Travel insurance certificate is due before departure ({d} days left).",
    "nt_ci_ask": "Please check in so your leader knows you are okay.",
    "nt_ci_miss": "A student in {c} has not checked in for {d} days.",
    "nt_ci_help": "A student in {c} needs help.",
    "nt_returned": "Welcome home. Share your story from {c}.",
    "nt_field_update": "News from {c}.",
    "nt_prayer_answered": "A prayer you prayed for was answered.",
    "nt_field_msg": "New message in the {c} field conversation."
  },
  "ko": {
    "nt_app": "{c} 신청: {s}",
    "nt_ext_ok": "연장이 승인되었어요. 새 귀국 예정일: {d}",
    "nt_ext_no": "{d}까지 연장 신청이 반려되었어요.",
    "nt_grad_ok": "수료 회원이 되었어요. 축하합니다!",
    "nt_grad_no": "수료 신청이 아직 승인되지 않았어요. 훈련을 이어가 주세요!",
    "nt_testi_ok": "간증 “{x}”이(가) 공개되었어요.",
    "nt_testi_no": "간증 “{x}”은(는) 공개되지 않았어요.",
    "nt_sup_ok": "후원 사연 “{x}”이(가) 공개되었어요.",
    "nt_sup_no": "후원 사연 “{x}”은(는) 공개되지 않았어요.",
    "nt_reply": "리더가 내 소감에 답글을 달았어요.",
    "nt_team": "{x}에 추가되었어요.",
    "nt_ins_ok": "여행자 보험이 확인되었습니다.",
    "nt_ins_fix": "여행자 보험 수정이 필요해요. 눌러서 본부 메모를 확인하세요.",
    "nt_report": "확인할 새 신고: {k}",
    "nt_generic": "새 소식이 있어요.",
    "st_submitted": "접수",
    "st_approved": "승인",
    "st_rejected": "반려",
    "st_preparing": "출국 준비",
    "st_on_field": "사역 중",
    "st_returned": "귀국",
    "rp_kind_message": "채팅 메시지",
    "rp_kind_prayer": "기도 제목",
    "rp_kind_testimony": "간증",
    "rp_kind_team_post": "팀 게시글",
    "rp_kind_user": "회원",
    "nt_leader_msg": "나라 리더가 메시지를 보냈어요.",
    "nt_student_msg": "학생이 메시지를 보냈어요.",
    "nt_new_app": "{c} 새 신청서가 들어왔어요.",
    "nt_dep": "{c} 출발까지 {d}일 남았어요. 준비 목록을 확인해 보세요.",
    "nt_dep_today": "오늘은 {c} 출발일이에요. 안전하게 다녀오세요.",
    "nt_ins_due": "여행자 보험 증서를 출발 전에 내야 해요 ({d}일 남음).",
    "nt_ci_ask": "리더가 안심하도록 체크인을 눌러 주세요.",
    "nt_ci_miss": "{c}의 학생이 {d}일째 체크인하지 않았어요.",
    "nt_ci_help": "{c}의 학생이 도움을 요청했어요.",
    "nt_returned": "잘 돌아왔어요. {c}에서의 이야기를 나눠 주세요.",
    "nt_field_update": "{c}에서 새 소식이 왔어요.",
    "nt_prayer_answered": "함께 기도한 제목이 응답되었어요.",
    "nt_field_msg": "{c} 선교지 대화방에 새 메시지가 있어요."
  }
};

type Notif = { id: number; user_id: string; kind: string; payload: Record<string, any> | null; link: string | null };

function fill(s: string, v: Record<string, string>) { return s.replace(/\{(\w+)\}/g, (_, k) => v[k] ?? ''); }
function fmtDay(d: string | undefined, lang: string) {
  if (!d) return '';
  const [y, m, dd] = d.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, dd)).toLocaleDateString(lang === 'ko' ? 'ko-KR' : 'en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });
}
// 앱 안의 notifText() 와 같은 문장
function bodyFor(n: Notif, lang: string, country: string) {
  const L = TEXT[lang] || TEXT.en, p = n.payload || {};
  const t = (k: string, v: Record<string, string> = {}) => fill(L[k] ?? TEXT.en[k] ?? '', v);
  switch (n.kind) {
    case 'app_status': return t('nt_app', { c: country, s: t('st_' + p.status) });
    case 'ext_status': return t(p.status === 'approved' ? 'nt_ext_ok' : 'nt_ext_no', { d: fmtDay(p.date, lang) });
    case 'ins_status': return t(p.status === 'verified' ? 'nt_ins_ok' : 'nt_ins_fix');
    case 'grad_status': return t(p.status === 'approved' ? 'nt_grad_ok' : 'nt_grad_no');
    case 'testi_status': return t(p.status === 'approved' ? 'nt_testi_ok' : 'nt_testi_no', { x: p.title || '' });
    case 'support_status': return t(p.status === 'approved' ? 'nt_sup_ok' : 'nt_sup_no', { x: p.title || '' });
    case 'feedback_reply': return t('nt_reply');
    case 'team_added': return t('nt_team', { x: p.team || '' });
    case 'report_new': return t('nt_report', { k: t('rp_kind_' + (p.kind || 'user')) });
    case 'leader_msg': return t('nt_leader_msg');
    case 'field_msg': return t('nt_field_msg', { c: country });
    case 'student_msg': return t('nt_student_msg');
    case 'new_app': return t('nt_new_app', { c: country });
    case 'field_update': return t('nt_field_update', { c: country });
    case 'prayer_answered': return t('nt_prayer_answered');
    case 'dep_remind': return p.days > 0 ? t('nt_dep', { d: String(p.days), c: country }) : t('nt_dep_today', { c: country });
    case 'ins_due': return t('nt_ins_due', { d: String(Math.max(0, p.days ?? 0)) });
    case 'checkin_ask': return t('nt_ci_ask');
    case 'checkin_miss': return t('nt_ci_miss', { c: country, d: String(p.days ?? '') });
    case 'checkin_help': return t('nt_ci_help', { c: country });
    case 'returned_testi': return t('nt_returned', { c: country });
    default: return t('nt_generic');
  }
}

// ---- Google OAuth 토큰 (서비스 계정 JWT, 55분 캐시) ----
let cached: { token: string; exp: number } | null = null;
function b64url(data: ArrayBuffer | string) {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = ''; bytes.forEach(b => s += String.fromCharCode(b));
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
async function accessToken(sa: { client_email: string; private_key: string }) {
  if (cached && cached.exp > Date.now() + 60_000) return cached.token;
  const now = Math.floor(Date.now() / 1000);
  const head = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(JSON.stringify({ iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600 }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), c => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${head}.${claim}`));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${head}.${claim}.${b64url(sig)}` }),
  });
  const j = await res.json();
  if (!res.ok) throw new Error('oauth: ' + JSON.stringify(j));
  cached = { token: j.access_token, exp: Date.now() + (j.expires_in - 300) * 1000 };
  return cached.token;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get('PUSH_WEBHOOK_SECRET');
  if (!secret || req.headers.get('x-webhook-secret') !== secret) return new Response('forbidden', { status: 403 });
  const body = await req.json().catch(() => null);
  const n: Notif | undefined = body?.record;
  if (body?.type !== 'INSERT' || body?.table !== 'notifications' || !n?.user_id) return new Response('ignored');

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const [{ data: tokens }, { data: prof }, { count: unread }] = await Promise.all([
    db.from('device_tokens').select('token,lang').eq('user_id', n.user_id),
    db.from('profiles').select('lang').eq('id', n.user_id).maybeSingle(),
    db.from('notifications').select('id', { count: 'exact', head: true }).eq('user_id', n.user_id).is('read_at', null),
  ]);
  if (!tokens?.length) return new Response('no devices');
  let country = { en: '', ko: '' };
  if (n.payload?.country_id) {
    const { data: c } = await db.from('countries').select('name_en,name_ko').eq('id', n.payload.country_id).maybeSingle();
    if (c) country = { en: c.name_en, ko: c.name_ko };
  }
  const sa = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT')!);
  const auth = await accessToken(sa);
  const badge = unread || 1;
  const results = await Promise.all(tokens.map(async ({ token, lang }) => {
    const L = (prof?.lang || lang) === 'ko' ? 'ko' : 'en';
    const message = {
      token,
      notification: { title: 'SVM', body: bodyFor(n, L, L === 'ko' ? country.ko : country.en) },
      data: { link: n.link || '#/notifications', kind: n.kind },
      android: { priority: 'high', notification: { notification_count: badge, icon: 'ic_stat_svm', color: '#F26722' } },
      apns: { payload: { aps: { badge, sound: 'default' } } },
    };
    const r = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST', headers: { Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message }),
    });
    if (r.ok) return 'sent';
    const err = await r.text();
    // 앱을 지웠거나 만료된 기기 토큰은 정리
    if (r.status === 404 || /UNREGISTERED|INVALID_ARGUMENT/.test(err)) await db.from('device_tokens').delete().eq('token', token);
    return 'failed: ' + r.status;
  }));
  return new Response(JSON.stringify(results), { headers: { 'Content-Type': 'application/json' } });
});
