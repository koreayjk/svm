\set ON_ERROR_STOP on
\set admin  '00000000-0000-0000-0000-0000000000a1'
\set lead   '00000000-0000-0000-0000-0000000000b1'
\set lead2  '00000000-0000-0000-0000-0000000000b2'
\set field  '00000000-0000-0000-0000-0000000000c1'
\set stud   '00000000-0000-0000-0000-0000000000d1'
\set stud2  '00000000-0000-0000-0000-0000000000d2'
\set stud3  '00000000-0000-0000-0000-0000000000d3'

-- ===== 준비: 사람 만들기 (가입 → 프로필 자동 생성) =====
insert into auth.users (id, email, raw_user_meta_data) values
  (:'admin',  'admin@t.org',  '{"name":"Ada Admin"}'),
  (:'lead',   'lead@t.org',   '{"name":"Lee Leader"}'),
  (:'lead2',  'lead2@t.org',  '{"name":"Lia Leader"}'),
  (:'field',  'field@t.org',  '{"name":"Fay Field"}'),
  (:'stud',   'stud@t.org',   '{"name":"Sam Student"}'),
  (:'stud2',  'stud2@t.org',  '{"name":"Sue Student"}'),
  (:'stud3',  'stud3@t.org',  '{"name":"Sid Student"}');
select test.ok((select count(*) from public.profiles) = 7, '가입하면 프로필이 자동으로 만들어진다');
select test.ok((select role from public.profiles where id = :'stud') = 'member', '새 회원은 일반 회원이다');
update public.profiles set role = 'admin' where id = :'admin';

-- 나라: 시드에서 한국(비민감)과 이집트(민감)
select id as kr from public.countries where code = 'KR' \gset
select id as eg from public.countries where code = 'EG' \gset
select test.ok(:kr is not null and :eg is not null, '나라 시드가 들어 있다');
select test.ok((select is_sensitive from public.countries where id = :eg), '이집트는 민감 국가다');
insert into public.country_leaders (country_id, user_id) values (:kr, :'lead');
insert into public.country_leaders (country_id, user_id) values (:eg, :'lead2');
insert into public.field_partners (country_id, user_id) values (:kr, :'field');

-- ===== 신청 → 승인 =====
set role authenticated; set app.uid = :'stud';
insert into public.applications (user_id, country_id, track, start_date, expected_return, contact, motivation)
  values (:'stud', :kr, 'short', current_date + 20, current_date + 50, 'sam@x', 'I want to serve') returning id as app \gset
select test.ok(:app is not null, '학생이 신청서를 낸다');
update public.applications set status = 'approved' where id = :app;
select test.ok((select status from public.applications where id = :app) = 'submitted', '학생은 스스로 승인할 수 없다 (바꿔도 그대로)');
select test.ok(test.n(format('select 1 from public.applications where id = %s', :app)) = 1, '학생은 자기 신청서를 본다');
set app.uid = :'stud2';
select test.ok(test.n('select 1 from public.applications') = 0, '다른 학생은 남의 신청서를 못 본다');
set app.uid = :'lead';
select test.ok(test.n('select 1 from public.applications') = 1, '한국 담당 리더는 한국 신청서를 본다');
set app.uid = :'lead2';
select test.ok(test.n('select 1 from public.applications') = 0, '이집트 담당 리더는 한국 신청서를 못 본다');
set app.uid = :'lead';
update public.applications set status = 'approved' where id = :app;
select test.ok((select status from public.applications where id = :app) = 'approved', '담당 리더가 승인한다');
reset role;
select test.ok((select count(*) from public.application_status_history where application_id = :app) >= 2, '상태 변경 이력이 남는다');
select test.ok((select count(*) from public.notifications where user_id = :'stud' and kind = 'app_status') >= 1, '승인되면 학생에게 알림이 간다');

-- ===== 출발 직전 비상 요청, 선교 중 체크인, 리더 확인 =====
set role authenticated; set app.uid = :'stud';
select test.throws(format($q$insert into public.field_checkins (application_id, user_id, status) values (%s, %L, 'safe')$q$, :app, :'stud'), '선교 중이 아니면 "안전해요" 체크인은 안 된다');
insert into public.field_checkins (application_id, user_id, status, note) values (:app, :'stud', 'need_help', 'lost at the airport');
select test.ok(true, '승인·준비 단계에서도 도움 요청은 보낼 수 있다');
reset role;
select test.ok((select count(*) from public.notifications where kind = 'checkin_help' and user_id in (:'lead', :'admin')) = 2, '도움 요청이 담당 리더와 관리자에게 알림으로 간다');
select test.ok((select count(*) from public.notifications where kind = 'checkin_help' and user_id = :'lead2') = 0, '다른 나라 리더에게는 가지 않는다');

-- 선교 중으로 바꾸고 체크인
reset role;
update public.applications set status = 'on_field' where id = :app;
set role authenticated; set app.uid = :'stud';
insert into public.field_checkins (application_id, user_id, status) values (:app, :'stud', 'safe');
select test.ok(true, '선교 중에는 "안전해요" 체크인을 남긴다');
select test.throws(format($q$insert into public.field_checkins (application_id, user_id, status) values (%s, %L, 'safe')$q$, :app, :'stud2'), '남의 이름으로는 체크인할 수 없다');
select id as ci from public.field_checkins where status = 'need_help' limit 1 \gset
update public.field_checkins set acked_at = now() where id = :ci;
select test.ok((select acked_at from public.field_checkins where id = :ci) is null, '학생은 리더 확인 표시를 스스로 못 넣는다');
set app.uid = :'lead';
update public.field_checkins set acked_at = now(), ack_note = 'On my way' where id = :ci;
select test.ok((select acked_by from public.field_checkins where id = :ci) = :'lead', '리더가 확인하면 누가 확인했는지 남는다');
select test.throws(format($q$update public.field_checkins set note = 'edited' where id = %s$q$, :ci), '리더도 도움 요청 내용은 못 고친다');
reset role;
select test.ok((select count(*) from public.notifications where user_id = :'stud' and kind = 'checkin_ack') = 1, '확인하면 학생에게 알림이 간다');

-- ===== 리더 방 (전체) · 나라별 리더 방 =====
set role authenticated; set app.uid = :'stud';
select test.ok(test.n('select 1 from public.network_messages') = 0, '학생은 리더 방을 못 읽는다');
select test.throws($q$insert into public.network_messages (user_id, body) values ('00000000-0000-0000-0000-0000000000d1', 'hi')$q$, '학생은 리더 방에 못 쓴다');
set app.uid = :'field';
insert into public.network_messages (user_id, body) values (:'field', 'Greetings from Korea');
select test.ok(true, '선교사님은 전체 리더 방에 쓴다');
set app.uid = :'lead2';
select test.ok(test.n('select 1 from public.network_messages') = 1, '다른 나라 리더도 전체 리더 방을 읽는다');
set app.uid = :'field';
insert into public.field_messages (country_id, user_id, body) values (:kr, :'field', 'KR leaders only');
select test.ok(true, '선교사님은 자기 나라 리더 방에 쓴다');
set app.uid = :'lead';
select test.ok(test.n('select 1 from public.field_messages') = 1, '한국 담당 리더는 한국 리더 방을 읽는다');
set app.uid = :'lead2';
select test.ok(test.n('select 1 from public.field_messages') = 0, '이집트 리더는 한국 리더 방을 못 읽는다');
select test.throws(format($q$insert into public.field_messages (country_id, user_id, body) values (%s, %L, 'x')$q$, :kr, :'lead2'), '다른 나라 리더는 한국 리더 방에 못 쓴다');
set app.uid = :'stud';
select test.ok(test.n('select 1 from public.field_messages') = 0, '학생은 나라 리더 방을 못 읽는다');

-- ===== 나라 페이지 편집: 리더·선교사님은 자기 나라만 =====
set app.uid = :'lead';
insert into public.country_photos (country_id, url, uploaded_by) values (:kr, 'https://x/kr.jpg', :'lead');
select test.ok(true, '나라 리더가 자기 나라에 사진을 올린다');
select test.throws(format($q$insert into public.country_photos (country_id, url, uploaded_by) values (%s, 'https://x/eg.jpg', %L)$q$, :eg, :'lead'), '나라 리더는 다른 나라에 사진을 못 올린다');
insert into public.country_videos (country_id, youtube_id, title) values (:kr, 'abcdefghijk', 'Hello');
select test.ok(true, '나라 리더가 자기 나라에 영상을 추가한다');
insert into public.field_updates (country_id, user_id, body) values (:kr, :'lead', 'Camp opens next week');
select test.ok(true, '나라 리더가 소식을 올린다');
update public.countries set name_en = 'Hacked', is_sensitive = true where id = :kr;
reset role;
select test.ok((select name_en from public.countries where id = :kr) <> 'Hacked' and not (select is_sensitive from public.countries where id = :kr), '리더가 나라 이름·민감 지정은 못 바꾼다');
set role authenticated; set app.uid = :'stud';
select test.throws(format($q$insert into public.country_photos (country_id, url, uploaded_by) values (%s, 'x', %L)$q$, :kr, :'stud'), '학생은 사진을 못 올린다');
select test.throws(format($q$insert into public.field_updates (country_id, user_id, body) values (%s, %L, 'x')$q$, :kr, :'stud'), '학생은 소식을 못 올린다');
select test.ok(test.n('select 1 from public.field_updates') = 1, '학생도 소식은 읽는다');
set app.uid = :'field';
insert into public.country_photos (country_id, url, uploaded_by) values (:kr, 'https://x/kr2.jpg', :'field');
select test.ok(true, '선교사님도 자기 나라에 사진을 올린다');
reset role;

-- ===== 컨퍼런스 등록 (누구나 넣기만, 읽기·체크인은 관리자) =====
set role anon; set app.uid = '';
insert into public.conference_registrations (full_name, email, role, lang) values ('Guest One', 'g1@x.org', 'student', 'en');
select test.ok(true, '로그인 안 한 사람도 컨퍼런스에 등록한다');
insert into public.conference_registrations (full_name, email, role, lang, group_name, group_size) values ('Group Lead', 'g2@x.org', 'leader', 'ko', 'Grace Church Youth', 14);
select test.ok(true, '단체 등록(이름·인원)을 넣는다');
select test.throws($q$insert into public.conference_registrations (full_name, email, role, lang, group_size) values ('Bad', 'g3@x.org', 'student', 'en', 1)$q$, '단체 인원이 2명 미만이면 거절');
select test.throws($q$insert into public.conference_registrations (full_name, email, role, lang, checked_in_at) values ('Sneaky', 'g4@x.org', 'student', 'en', now())$q$, '등록 양식으로 체크인 표시를 넣을 수 없다');
select test.throws($q$insert into public.conference_registrations (full_name, email, role, lang, walk_in) values ('Sneaky2', 'g5@x.org', 'student', 'en', true)$q$, '등록 양식으로 현장등록 표시를 넣을 수 없다');
select test.throws($q$insert into public.conference_registrations (full_name, email, role, lang) values ('Dup', 'G1@x.org', 'student', 'en')$q$, '같은 이메일(대소문자 무관)은 한 번만');
select test.ok(test.n('select 1 from public.conference_registrations') = 0, '로그인 안 한 사람은 등록자 목록을 못 읽는다');
set role authenticated; set app.uid = :'stud';
select test.ok(test.n('select 1 from public.conference_registrations') = 0, '일반 회원도 등록자 목록을 못 읽는다');
set app.uid = :'lead';
select test.ok(test.n('select 1 from public.conference_registrations') = 0, '나라 리더도 등록자 목록을 못 읽는다');
set app.uid = :'admin';
select test.ok(test.n('select 1 from public.conference_registrations') = 2, '관리자는 등록자 목록을 읽는다');
update public.conference_registrations set checked_in_at = now(), checked_in_by = :'admin' where email = 'g1@x.org';
select test.ok((select checked_in_at from public.conference_registrations where email = 'g1@x.org') is not null, '관리자는 체크인 처리를 한다');
insert into public.conference_registrations (full_name, email, role, lang, walk_in, checked_in_at, checked_in_by, group_name, group_size)
  values ('Walk In', 'walkin-1@walkin.svm.invalid', 'other', 'en', true, now(), :'admin', 'Campus Fellowship', 6);
select test.ok(true, '관리자는 현장 등록(단체)을 넣는다');
set app.uid = :'stud';
insert into public.conference_checkins (user_id) values (:'stud');
select test.ok(true, '학생이 앱에서 "도착했어요"를 누른다');
select test.throws(format($q$insert into public.conference_checkins (user_id) values (%L)$q$, :'stud2'), '남의 이름으로 도착 체크인은 안 된다');
select test.ok(test.n('select 1 from public.conference_checkins') = 1, '내 도착 기록만 보인다');
reset role;

-- ===== 개선 제안 게시판 =====
set role authenticated; set app.uid = :'stud';
insert into public.feedback_posts (user_id, kind, body, photos) values (:'stud', 'idea', 'Dark mode please', '{https://x/a.jpg,https://x/b.jpg}') returning id as fb \gset
select test.ok(:fb is not null, '회원이 개선 제안(사진 2장)을 올린다');
select test.throws(format($q$insert into public.feedback_posts (user_id, body, photos) values (%L, 'too many', '{a,b,c,d}')$q$, :'stud'), '사진은 3장까지');
select test.throws(format($q$insert into public.feedback_posts (user_id, body, status) values (%L, 'sneaky', 'done')$q$, :'stud'), '올릴 때 상태를 완료로 못 넣는다');
set app.uid = :'stud2';
insert into public.feedback_comments (post_id, user_id, body) values (:fb, :'stud2', '+1');
select test.ok(true, '다른 회원이 댓글을 단다');
update public.feedback_posts set status = 'done' where id = :fb;
select test.ok((select status from public.feedback_posts where id = :fb) = 'open', '회원은 상태를 못 바꾼다');
delete from public.feedback_posts where id = :fb;
select test.ok(test.n(format('select 1 from public.feedback_posts where id = %s', :fb)) = 1, '남의 글은 못 지운다');
set app.uid = :'admin';
update public.feedback_posts set status = 'planned' where id = :fb;
select test.ok((select status from public.feedback_posts where id = :fb) = 'planned', '관리자는 상태를 바꾼다');
reset role;
select test.ok((select count(*) from public.notifications where kind = 'fb_comment' and user_id = :'stud') = 1, '댓글이 달리면 글쓴이에게 알림');
select test.ok((select count(*) from public.notifications where kind = 'fb_status' and user_id = :'stud') = 1, '상태가 바뀌면 글쓴이에게 알림');
select test.ok((select count(*) from public.notifications where kind = 'fb_new' and user_id = :'admin') = 1, '새 글이 오면 관리자에게 알림');

-- ===== 여정 일정표: 본인과 담당 리더만 =====
set role authenticated; set app.uid = :'stud';
insert into public.application_trips (application_id, out_flight, local_contact) values (:app, 'AA 100', 'Pastor Kim');
select test.ok(true, '학생이 자기 여정 일정을 적는다');
set app.uid = :'stud2';
select test.ok(test.n('select 1 from public.application_trips') = 0, '다른 학생은 남의 일정을 못 본다');
set app.uid = :'lead';
select test.ok(test.n('select 1 from public.application_trips') = 1, '담당 리더는 일정을 본다');
set app.uid = :'lead2';
select test.ok(test.n('select 1 from public.application_trips') = 0, '다른 나라 리더는 못 본다');
reset role;

-- ===== 기도 짝: 같은 나라를 품은 사람끼리, 민감 국가는 제외 =====
insert into public.nation_pledges (user_id, country_id) values (:'stud', :kr), (:'stud2', :kr), (:'stud', :eg), (:'stud2', :eg);
set role authenticated; set app.uid = :'stud';
select public.find_prayer_partner(:kr) as pair \gset
select test.ok(:pair is not null, '같은 나라를 품은 두 학생이 기도 짝이 된다');
select test.throws(format('select public.find_prayer_partner(%s)', :eg), '민감 국가에서는 기도 짝을 만들지 않는다');
select test.throws(format('select public.find_prayer_partner(%s)', (select id from public.countries where code = 'JP')), '품지 않은 나라에서는 찾을 수 없다');
insert into public.prayer_pair_msgs (pair_id, user_id, body) values (:pair, :'stud', 'Praying for you');
set app.uid = :'stud3';
select test.ok(test.n('select 1 from public.prayer_pair_msgs') = 0, '짝이 아닌 사람은 대화를 못 본다');
select test.throws(format($q$insert into public.prayer_pair_msgs (pair_id, user_id, body) values (%s, %L, 'x')$q$, :pair, :'stud3'), '짝이 아닌 사람은 끼어들 수 없다');
reset role;

-- ===== 신고 · 알림 · 소식 구독 =====
set role authenticated; set app.uid = :'stud2';
insert into public.content_reports (reporter_id, target_kind, target_id, reason) values (:'stud2', 'feedback', :fb, 'spam');
select test.ok(true, '개선 제안 글을 신고할 수 있다');
select test.ok(test.n('select 1 from public.content_reports') = 0, '신고 내용은 신고자도 못 읽는다 (관리자만)');
set role anon; set app.uid = '';
insert into public.newsletter_signups (email) values ('news@x.org');
select test.ok(true, '홈페이지에서 소식 받기 이메일을 남긴다');
select test.ok(test.n('select 1 from public.newsletter_signups') = 0, '소식 받기 목록은 공개되지 않는다');
reset role;

-- ===== 계정 삭제 =====
set role authenticated; set app.uid = :'admin';
select test.throws('select public.delete_my_account()', '마지막 관리자는 계정을 지울 수 없다');
set app.uid = :'stud3';
select public.delete_my_account();
reset role;
select test.ok((select count(*) from public.profiles where id = :'stud3') = 0, '일반 회원은 계정을 지우면 프로필도 사라진다');

-- ===== 채팅 기본 기능: 답장 · 반응 · 수정/삭제 · 사진 =====
insert into public.room_members (user_id, country_id) values (:'stud', :kr), (:'stud2', :kr);
set role authenticated; set app.uid = :'stud';
insert into public.messages (country_id, user_id, body) values (:kr, :'stud', 'Hello Korea team') returning id as m1 \gset
select test.ok(:m1 is not null, '나라 방에 글을 쓴다');
set app.uid = :'stud2';
insert into public.messages (country_id, user_id, body, reply_to) values (:kr, :'stud2', 'Welcome!', :m1) returning id as m2 \gset
select test.ok((select reply_to from public.messages where id = :m2) = :m1, '글에 답장한다');
insert into public.messages (country_id, user_id, body, image_url) values (:kr, :'stud2', '', 'https://x/p.jpg') returning id as m3 \gset
select test.ok(:m3 is not null, '글 없이 사진만 보낼 수 있다');
select test.throws(format($q$insert into public.messages (country_id, user_id, body) values (%s, %L, '')$q$, :kr, :'stud2'), '글도 사진도 없으면 보낼 수 없다');
insert into public.message_reactions (kind, message_id, user_id, emoji) values ('room', :m1, :'stud2', '🙏');
select test.ok(true, '남의 글에 이모지 반응을 남긴다');
select test.throws(format($q$insert into public.message_reactions (kind, message_id, user_id, emoji) values ('room', %s, %L, '🙏')$q$, :m1, :'stud2'), '같은 반응을 두 번은 못 남긴다');
select test.throws(format($q$insert into public.message_reactions (kind, message_id, user_id, emoji) values ('room', %s, %L, '💩')$q$, :m1, :'stud2'), '정해진 이모지만 쓸 수 있다');
select test.throws(format($q$insert into public.message_reactions (kind, message_id, user_id, emoji) values ('room', %s, %L, '👍')$q$, :m1, :'stud'), '남의 이름으로 반응을 남길 수 없다');
set app.uid = :'stud';
select test.ok(test.n(format($q$select 1 from public.message_reactions where message_id = %s$q$, :m1)) = 1, '반응은 모두에게 보인다');
-- 수정
update public.messages set body = 'Hello Korea team!!' where id = :m1;
select test.ok((select body from public.messages where id = :m1) = 'Hello Korea team!!' and (select edited_at from public.messages where id = :m1) is not null, '내 글을 고치면 "수정됨" 시각이 남는다');
select test.throws(format($q$update public.messages set user_id = %L where id = %s$q$, :'stud2', :m1), '글쓴이를 바꿀 수 없다');
select test.throws(format($q$update public.messages set image_url = 'https://evil/x.jpg' where id = %s$q$, :m1), '이미 보낸 글에 사진을 몰래 못 붙인다');
update public.messages set body = 'hijack' where id = :m2;
select test.ok((select body from public.messages where id = :m2) = 'Welcome!', '남의 글은 못 고친다');
-- 삭제 (삭제 표시)
select public.delete_my_message(:m1);
select test.ok(test.n(format('select 1 from public.messages where id = %s', :m1)) = 0, '내 글을 지우면 더 이상 보이지 않는다');
select test.throws(format('select public.delete_my_message(%s)', :m2), '남의 글은 지울 수 없다');
reset role;
select test.ok((select count(*) from public.message_reactions where message_id = :m1) = 1, '(기록은 남아 있다)');
set role authenticated; set app.uid = :'stud2';
select test.ok(test.n(format($q$select 1 from public.message_reactions where message_id = %s$q$, :m1)) = 0, '지워진 글의 반응은 보이지 않는다');
select test.throws(format($q$select public.delete_my_message(%s)$q$, :m1), '이미 지운 글을 다시 지울 수 없다');
delete from public.message_reactions where user_id = :'stud2' and message_id = :m1;
reset role;
select test.ok((select count(*) from public.notifications where kind = 'chat_reply' and user_id = :'stud') = 1, '답장이 달리면 글쓴이에게 알림');
-- 리더 방에도 같은 기능
set role authenticated; set app.uid = :'field';
insert into public.network_messages (user_id, body) values (:'field', 'Leaders only hello') returning id as n1 \gset
insert into public.message_reactions (kind, message_id, user_id, emoji) values ('network', :n1, :'field', '👍');
select test.ok(true, '리더 방 글에도 반응을 남긴다');
update public.network_messages set body = 'Leaders only hello (edited)' where id = :n1;
select test.ok((select edited_at from public.network_messages where id = :n1) is not null, '리더 방 글도 고칠 수 있다');
delete from public.network_messages where id = :n1;
select test.ok(test.n(format('select 1 from public.network_messages where id = %s', :n1)) = 0, '리더 방 글을 지운다');
reset role;
select test.ok((select count(*) from public.message_reactions where kind = 'network' and message_id = :n1) = 0, '글을 지우면 그 글의 반응도 정리된다');
set role authenticated; set app.uid = :'field';
insert into public.network_messages (user_id, body) values (:'field', 'Second one') returning id as n2 \gset
set app.uid = :'stud';
select test.throws(format($q$insert into public.message_reactions (kind, message_id, user_id, emoji) values ('network', %s, %L, '👍')$q$, :n2, :'stud'), '학생은 리더 방 글에 반응을 못 남긴다');
select test.ok(test.n(format($q$select 1 from public.message_reactions where kind = 'network' and message_id = %s$q$, :n2)) = 0, '학생은 리더 방 반응을 못 본다');
reset role;
