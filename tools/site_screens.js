// 홈페이지·앱 소개 페이지의 폰 화면 사진(assets/screens/*-{en,ko}.jpg)을 데모 앱으로 새로 찍습니다.
// 사용: python3 -m http.server 8811  →  node tools/site_screens.js http://localhost:8811
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const BASE = process.argv[2] || 'http://localhost:8811', OUT = 'assets/screens';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1.5, isMobile: true, hasTouch: true });
  const p = await ctx.newPage();
  await p.addInitScript(() => { document.addEventListener('DOMContentLoaded', () => { const st = document.createElement('style'); st.textContent = '.apphead .tag{display:none!important}'; document.head.appendChild(st); }); });
  const shot = (name, lang) => p.screenshot({ path: `${OUT}/${name}-${lang}.jpg`, type: 'jpeg', quality: 86 });
  const go = async h => { await p.evaluate(h => { location.hash = h; }, h); await sleep(1100); };
  const setLang = async lang => { await p.click(`.lang-toggle [data-lang=${lang}]`); await sleep(500); };
  await p.goto(BASE + '/app/?demo'); await p.waitForSelector('#auth-form');
  // 가입 화면 (가입 전)
  for (const lang of ['en', 'ko']) { await setLang(lang); const su = p.locator('[data-mode=signup]'); if (await su.count()) { await su.first().click(); await sleep(300); } await shot('signup', lang); }
  await setLang('en');
  await p.fill('[name=name]', 'Grace Kim'); await p.fill('[name=email]', 'grace@svm.org'); await p.fill('[name=password]', 'secret12'); await p.check('[name=agree]');
  await p.click('#auth-form button[type=submit]'); await sleep(1800);
  // 훈련 진행 상황을 보기 좋게 채운다
  await p.evaluate(() => {
    const db = JSON.parse(localStorage.getItem('svm_demo_db_v5')), me = db.session, now = new Date().toISOString(), ago = d => new Date(Date.now() - d * 864e5).toISOString();
    const add = (track, n, conf, wait, note) => { for (let k = 1; k <= n; k++) db.training_progress.push({ user_id: me, track, item: k, note: note || null, done_at: ago(40 - k), confirmed_at: k <= conf ? ago(35 - k) : null, confirmed_by: null }); };
    add('explore', 4, 3); add('perspectives', 8, 6); add('sermon', 15, 12, 0, 'My notes on this sermon: God has always been moving toward every people.');
    localStorage.setItem('svm_demo_db_v5', JSON.stringify(db));
  });
  await p.reload(); await sleep(1500);
  await go('#/countries/MX'); await p.click('#pledge-btn').catch(() => {}); await sleep(600);
  await go('#/rooms/KR'); await p.click('#room-join').catch(() => {}); await sleep(900);
  for (const lang of ['en', 'ko']) {
    await go('#/home'); await setLang(lang);
    await go('#/home'); await shot('home', lang);
    await go('#/countries/MX'); await shot('country', lang);
    await go('#/countries/MX');
    await p.evaluate(() => { const e = document.querySelector('#pledge-btn'); const c = e && (e.closest('section') || e); if (c) window.scrollTo(0, c.getBoundingClientRect().top + window.scrollY - 170); }); await sleep(500);
    await shot('pledge', lang);
    await go('#/train'); await p.evaluate(() => window.scrollTo(0, 0)); await sleep(400); await shot('train', lang);
    await go('#/rooms/KR'); await sleep(500); await shot('room', lang);
    await go('#/admin'); await shot('admin', lang);
  }
  await b.close();
  console.log('done');
})();
