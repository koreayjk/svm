// 스토어 등록용 스크린샷 — 데모 모드(?demo)로 앱을 돌려 화면을 찍습니다.
// 사용: node tools/store_screenshots.js http://localhost:8811 store/screenshots
//   (먼저 `python3 -m http.server 8811` 로 저장소를 열어 두고, playwright 가 설치돼 있어야 합니다)
// 결과: <out>/ios/{en,ko}/NN-이름.jpg (1290×2796) · <out>/android/{en,ko}/NN-이름.jpg (1080×1920)
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const fs = require('fs');
const BASE = process.argv[2] || 'http://localhost:8811', OUT = process.argv[3] || 'store/screenshots';
const DEVICES = { ios: { w: 430, h: 932, scale: 3 }, android: { w: 360, h: 640, scale: 3 } };
const addDays = n => new Date(Date.now() + n * 864e5).toISOString().slice(0, 10);

async function run(name, dev) {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: dev.w, height: dev.h }, deviceScaleFactor: dev.scale, isMobile: true, hasTouch: true });
  const p = await ctx.newPage();
  await p.addInitScript(() => { const st = document.createElement('style'); st.textContent = '.apphead .tag{display:none!important}'; document.addEventListener('DOMContentLoaded', () => document.head.appendChild(st)); });
  const settle = (ms = 900) => p.waitForTimeout(ms);
  const go = async h => { await p.goto(BASE + '/app/?demo' + h); await settle(1100); };
  const signup = async (n, email) => { await p.waitForSelector('#auth-form'); const su = p.locator('[data-mode=signup]'); if (await su.count()) { await su.first().click(); await settle(300); }
    await p.fill('[name=name]', n); await p.fill('[name=email]', email); await p.fill('[name=password]', 'secret1'); await p.check('[name=agree]'); await p.click('#auth-form button[type=submit]'); await p.waitForSelector('.apphead'); await settle(); };
  const login = async email => { await go('#/home'); await p.waitForSelector('#auth-form'); const l = p.locator('[data-mode=login]'); if (await l.count()) { await l.first().click(); await settle(300); } await p.fill('[name=email]', email); await p.fill('[name=password]', 'secret1'); await p.click('#auth-form button[type=submit]'); await p.waitForSelector('.apphead'); await settle(); };
  const logout = async () => { await go('#/my'); await p.click('#logout-btn'); await settle(); };
  const setStatus = async (who, status) => { await login('grace@svm.org'); await go('#/admin'); await p.click('[data-admin-tab=applications]').catch(() => {}); await settle(800); await p.click('[data-app-filter=all]').catch(() => {}); await settle(600);
    const r = p.locator('details.adm-app', { hasText: who }); if ((await r.getAttribute('open')) === null) await r.locator('summary').click();
    await r.locator('select[name=status]').selectOption(status); await r.locator('form[data-app-form] button').click(); await settle(1000); await logout(); };

  await go(''); await signup('Grace Admin', 'grace@svm.org'); await logout();
  await signup('Sam Park', 'sam@svm.org');
  await go('#/countries/MX'); await p.click('#pledge-btn'); await settle(700);
  await go('#/apply/MX'); await p.fill('[name=start_date]', addDays(10)); await p.fill('[name=motivation]', 'I want to serve with the church in Mexico City.'); await p.click('#apply-form button[type=submit]'); await p.waitForSelector('.timeline'); await settle();
  const appHash = p.url().split('#')[1];
  await logout();
  await setStatus('Sam', 'approved');
  await login('sam@svm.org');

  const shots = {};
  const snap = async (lang, idx, label, hash, scrollSel) => {
    const dir = `${OUT}/${name}/${lang}`; fs.mkdirSync(dir, { recursive: true });
    await go(hash); await settle(900);
    if (scrollSel) { await p.evaluate(s => { const e0 = document.querySelector(s), e = e0 && (e0.closest('section') || e0); if (e) window.scrollTo(0, e.getBoundingClientRect().top + window.scrollY - 76); }, scrollSel); await settle(500); }
    await p.screenshot({ path: `${dir}/${String(idx).padStart(2, '0')}-${label}.jpg`, type: 'jpeg', quality: 88 });
  };
  for (const lang of ['en', 'ko']) {
    await go('#/home'); await p.click(`.lang-toggle [data-lang=${lang}]`); await settle(500);
    await snap(lang, 1, 'home', '#/home');
    await snap(lang, 2, 'countries', '#/countries');
    await snap(lang, 3, 'country', '#/countries/MX');
    await snap(lang, 4, 'prepare', '#' + appHash, '#prep-count');
    await snap(lang, 5, 'news', '#/feed');
    await snap(lang, 6, 'prayers', '#/prayers');
  }
  await logout();
  await setStatus('Sam', 'on_field');
  await login('sam@svm.org');
  for (const lang of ['en', 'ko']) {
    await go('#/home'); await p.click(`.lang-toggle [data-lang=${lang}]`); await settle(500);
    await snap(lang, 7, 'checkin', '#' + appHash, '#checkin-form');
  }
  await b.close();
}
(async () => { for (const [n, d] of Object.entries(DEVICES)) { await run(n, d); console.log('done', n); } })();
