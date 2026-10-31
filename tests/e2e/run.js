// 앱 화면 흐름 테스트 (데모 모드 — 실제 DB 를 건드리지 않습니다)
//   사용: node tests/e2e/run.js [http://localhost:8800]   (주소가 없으면 저장소를 임시로 서빙합니다)
//   필요: playwright (npm i -D playwright, 또는 PLAYWRIGHT_PATH)
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const http = require('http'), fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '../..');
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml', '.jpg': 'image/jpeg', '.png': 'image/png', '.json': 'application/json', '.webmanifest': 'application/json' };
let server, BASE = process.argv[2];
function serve() {
  return new Promise(res => {
    server = http.createServer((req, rsp) => {
      let p = decodeURIComponent(req.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
      const f = path.join(ROOT, p);
      if (!f.startsWith(ROOT) || !fs.existsSync(f)) { rsp.writeHead(404); return rsp.end(); }
      rsp.writeHead(200, { 'Content-Type': MIME[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(rsp);
    }).listen(0, () => res('http://localhost:' + server.address().port));
  });
}
let pass = 0, fail = 0;
const ok = (c, msg) => { if (c) { pass++; console.log('  ✓', msg); } else { fail++; console.log('  ✗ FAIL:', msg); } };
const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  if (!BASE) BASE = await serve();
  const b = await chromium.launch();
  const mk = async (w = 430, h = 900) => { const ctx = await b.newContext({ viewport: { width: w, height: h } }); const p = await ctx.newPage(); p.errors = []; p.on('pageerror', e => p.errors.push(e.message)); return p; };
  const go = async (p, hash) => { await p.evaluate(h => { location.hash = h; }, hash); await sleep(900); };
  const signup = async (p, name, email) => {
    await p.goto(BASE + '/app/?demo'); await p.waitForSelector('#auth-form');
    await p.fill('[name=name]', name); await p.fill('[name=email]', email); await p.fill('[name=password]', 'secret12'); await p.check('[name=agree]');
    await p.click('#auth-form button[type=submit]'); await sleep(1800);
  };
  // 데모 DB 를 직접 만져 상황을 만든다 (예: 승인된 신청서)
  const setStatus = (p, id, status) => p.evaluate(([id, status]) => { const db = JSON.parse(localStorage.getItem('svm_demo_db_v5')); const a = db.applications.find(x => String(x.id) === String(id)); a.status = status; a.user_id = db.session; localStorage.setItem('svm_demo_db_v5', JSON.stringify(db)); }, [id, status]);
  const patchDb = (p, fn) => p.evaluate(src => { const db = JSON.parse(localStorage.getItem('svm_demo_db_v5')); (new Function('db', src))(db); localStorage.setItem('svm_demo_db_v5', JSON.stringify(db)); }, `(${fn.toString()})(db)`);

  console.log('1. 가입과 첫 화면');
  let p = await mk();
  await signup(p, 'First Admin', 'admin@t.org');
  ok(await p.locator('.island').count() === 1, '가입하면 앱 화면이 열린다');
  ok((await p.locator('.island a').allInnerTexts()).map(x => x.trim()).join(',') === 'Home,Countries,Train,Chat,Community,My,Admin', '하단 메뉴: 홈·선교지·훈련·채팅·커뮤니티·마이·관리');
  ok(await p.locator('#view h1').first().isVisible(), '홈 제목이 보인다');

  console.log('2. 선교지 신청');
  await go(p, '#/countries/KR');
  ok(await p.locator('#pledge-btn').count() === 1, '나라 페이지에 "이름 쓰기" 버튼');
  await p.click('#pledge-btn'); await sleep(700);
  await go(p, '#/apply/MX');
  const d = new Date(Date.now() + 20 * 864e5).toISOString().slice(0, 10);
  await p.fill('[name=start_date]', d); await p.fill('[name=motivation]', 'I want to serve with the church.');
  await p.click('#apply-form button[type=submit]'); await sleep(1500);
  ok(/#\/apps\/\d+/.test(p.url()), '신청서를 내면 내 신청 화면으로 간다');

  console.log('3. 관리자 승인 → 출발 D-day 카드 → 선교 중 → 비상 버튼');
  const appId = p.url().split('/').pop();
  await go(p, '#/admin'); await p.locator('a,button').filter({ hasText: /^Applications/ }).first().click(); await sleep(800);
  ok(await p.locator('.attn-list').count() === 1, '관리자 신청 화면에 "지금 챙겨 주세요" 패널');
  await setStatus(p, appId, 'approved');
  await p.reload(); await sleep(1200); await go(p, '#/home'); await sleep(600);
  ok(await p.locator('.trip-home').count() === 1, '승인되면 홈에 출발 D-day 카드');
  await go(p, '#/apps/' + appId);
  ok(await p.locator('#trip-form').count() === 1, '신청 화면에 여정 일정표');
  await p.fill('[name=out_flight]', 'AA 100'); await p.click('#trip-form button[type=submit]'); await sleep(900);
  ok((await p.locator('.trip-sum').innerText()).includes('AA 100'), '항공편을 저장하면 요약에 보인다');
  await setStatus(p, appId, 'on_field');
  await p.reload(); await sleep(1200); await go(p, '#/home'); await sleep(600);
  ok(await p.locator('.sos-home').count() === 1, '선교 중에는 홈에 "도움이 필요하세요?"');
  await p.click('.sos-home'); await sleep(900);
  await p.fill('#sos-form textarea', 'Lost my passport');
  await p.click('#sos-send'); await sleep(300); await p.click('#sos-send'); await sleep(1300);
  ok((await p.locator('#view').innerText()).toLowerCase().includes('alert sent'), '비상 버튼을 두 번 눌러 보낸다');

  console.log('4. 채팅 · 커뮤니티 · 개선 제안');
  await go(p, '#/chat');
  ok(await p.locator('a[href="#/network"]').count() === 1, '관리자에게는 채팅에 리더 방이 보인다');
  await go(p, '#/rooms/KR'); await p.click('#room-join').catch(() => {}); await sleep(1000);
  await p.fill('#composer textarea', 'Hello team'); await p.click('#composer button'); await sleep(900);
  ok((await p.locator('#chat').innerText()).includes('Hello team'), '나라 방에 메시지를 보낸다');
  await go(p, '#/ideas');
  await p.fill('#fb-form textarea', 'Please add a calendar view'); await p.click('#fb-form button[type=submit]'); await sleep(1200);
  ok((await p.locator('#view').innerText()).includes('Please add a calendar view'), '개선 제안 글을 올린다');

  console.log('5. 컨퍼런스 접수 (관리자)');
  await go(p, '#/conference');
  ok((await p.locator('.cf-stats').count()) === 1, '접수 화면에 인원 현황');
  const before = (await p.locator('.cf-stats').innerText()).replace(/\s+/g, ' ');
  await p.locator('[data-cf]').first().click(); await sleep(800);
  ok((await p.locator('.cf-stats').innerText()).replace(/\s+/g, ' ') !== before, '체크인하면 숫자가 바뀐다');

  console.log('6. 일반 학생 권한 (관리자 화면 · 리더 방이 안 보여야 한다)');
  const s = await mk();
  await s.goto(BASE + '/app/?demo'); await sleep(500);
  await s.evaluate(() => localStorage.clear()); // 새 데모 DB
  await signup(s, 'Plain Student', 'student@t.org');
  // 첫 가입자가 관리자라서, 두 번째 사람은 새 브라우저에서 가입해도 데모 DB 가 따로라 관리자가 된다 → 역할을 일반으로
  await patchDb(s, db => { db.profiles.find(x => x.id === db.session).role = 'member'; });
  await s.reload(); await sleep(1500);
  ok((await s.locator('.island a').allInnerTexts()).map(x => x.trim()).join(',') === 'Home,Countries,Train,Chat,Community,My', '학생에게는 관리 메뉴가 없다');
  await go(s, '#/chat');
  ok(await s.locator('a[href="#/network"]').count() === 0, '학생에게는 리더 방이 안 보인다');
  await go(s, '#/conference');
  ok(!(await s.locator('.cf-stats').count()), '학생은 접수 화면을 못 연다');
  await go(s, '#/admin');
  ok(!(await s.locator('.attn-list').count()), '학생은 관리자 화면을 못 연다');

  console.log('7. 컴퓨터 화면 배치');
  const w = await mk(1440, 900);
  await signup(w, 'Desk Admin', 'desk@t.org');
  ok(await w.locator('.island').evaluate(e => getComputedStyle(e).position === 'fixed' && e.getBoundingClientRect().left === 0 && e.getBoundingClientRect().height > 500), '컴퓨터에서는 왼쪽 사이드바');
  await go(w, '#/rooms/KR'); await w.click('#room-join').catch(() => {}); await sleep(900);
  ok(await w.locator('.room-side').isVisible(), '채팅방 오른쪽에 참여자 패널');
  ok(await w.evaluate(() => document.documentElement.scrollWidth <= innerWidth), '가로로 넘치지 않는다');

  const errs = [p, s, w].flatMap(x => x.errors);
  ok(errs.length === 0, '화면에서 자바스크립트 오류가 없다' + (errs.length ? ' — ' + errs[0] : ''));
  await b.close(); if (server) server.close();
  console.log(`\n—— ${pass} 개 통과, ${fail} 개 실패`);
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error(e); process.exit(2); });
