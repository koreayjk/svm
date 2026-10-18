// SVM site — 홈페이지(/)와 컨퍼런스(/conference/) 공통 스크립트
// 페이지는 이 파일보다 먼저 window.SVM_BASE('' 또는 '../')와 window.KO(한국어 문구)를 정의합니다.
(function () {
  const BASE = window.SVM_BASE || '';
  const KO = Object.assign({
    nav_movement: '운동 소개', nav_students: '가려는 학생', nav_fields: '선교지', nav_app: '앱', nav_host: '선교지·현지 교회',
    nav_conf: '11/20 컨퍼런스', nav_home: 'SVM 홈', open_app: '앱 열기',
    lg_now: '지금 파송 · 7개국', lg_future: '기도하며 준비하는 나라들',
    ft_tag: '학생자원운동 · 텍사스 브라이언–컬리지 스테이션', ft_site: '사이트', ft_more: '함께하기',
    ft_l_home: 'SVM 홈', ft_l_conf: '미션 컨퍼런스 2026', ft_l_app: 'SVM 앱', ft_l_reg: '컨퍼런스 등록', ft_l_host: '선교지 협력', ft_l_faq: '자주 묻는 질문', ft_l_privacy: '개인정보', ft_l_terms: '이용약관',
    ft_hosted: 'IM Mission Foundation Group Corp 주최',
  }, window.KO || {});

  const EN = {};
  document.querySelectorAll('[data-k]').forEach(el => { EN[el.dataset.k] = el.hasAttribute('data-html') ? el.innerHTML : el.textContent; });
  document.querySelectorAll('[data-ph]').forEach(el => { EN['ph:' + el.dataset.ph] = el.getAttribute('placeholder') || ''; });

  function setLang(lang) {
    const dict = lang === 'ko' ? KO : EN;
    document.querySelectorAll('[data-k]').forEach(el => {
      const v = dict[el.dataset.k] ?? EN[el.dataset.k];
      if (v == null) return;
      if (el.hasAttribute('data-html') || /<(em|b|br)>/.test(v)) el.innerHTML = v; else el.textContent = v;
    });
    document.querySelectorAll('[data-ph]').forEach(el => {
      const v = lang === 'ko' ? KO['ph:' + el.dataset.ph] : EN['ph:' + el.dataset.ph];
      if (v != null) el.setAttribute('placeholder', v);
    });
    document.documentElement.lang = lang;
    document.querySelectorAll('img[data-img]').forEach(im => { im.src = `${BASE}assets/screens/${im.dataset.img}-${lang}.jpg`; });
    document.querySelectorAll('[data-lang]').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.lang === lang)));
    try { localStorage.setItem('svm_lang', lang); } catch (e) {}
    document.dispatchEvent(new CustomEvent('svm:lang', { detail: lang }));
  }
  window.svmLang = () => document.documentElement.lang === 'ko' ? 'ko' : 'en';
  window.svmT = (key) => (svmLang() === 'ko' ? KO[key] : EN[key]) ?? EN[key] ?? key;
  document.querySelectorAll('[data-lang]').forEach(b => b.addEventListener('click', () => setLang(b.dataset.lang)));

  // 앱 링크 — 공유용 미리보기 빌드에서는 window.SVM_APP_URL 로 바뀝니다
  if (window.SVM_APP_URL) document.querySelectorAll('.app-link').forEach(a => { a.href = window.SVM_APP_URL; a.target = '_blank'; a.rel = 'noopener'; });

  // 헤더: 사진 위에서는 투명, 스크롤하면 기본 스타일
  const top = document.querySelector('.top[data-photo]');
  if (top) {
    const onScroll = () => top.classList.toggle('on-photo', window.scrollY < 40);
    onScroll(); window.addEventListener('scroll', onScroll, { passive: true });
  }

  // D-day (Bryan/College Station 기준, 11월 20일)
  document.querySelectorAll('[data-dday]').forEach(el => {
    const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Chicago', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
    const d = Math.round((Date.parse('2026-11-20T00:00:00Z') - Date.parse(today + 'T00:00:00Z')) / 86400000);
    el.textContent = d > 0 ? 'D-' + d : d === 0 ? 'D-DAY' : '2026';
  });

  // 유튜브: 누르기 전에는 썸네일만 (외부 쿠키 없음, 페이지 가벼움)
  document.querySelectorAll('.video[data-yt]').forEach(v => {
    const id = v.dataset.yt;
    const b = document.createElement('button');
    b.type = 'button';
    b.setAttribute('aria-label', (v.dataset.title || 'Video') + ' — play');
    b.style.backgroundImage = `url(https://i.ytimg.com/vi/${id}/hqdefault.jpg)`;
    b.innerHTML = '<i><svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M7 4.5v15l12.5-7.5z"/></svg></i>';
    b.addEventListener('click', () => {
      v.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${id}?autoplay=1&rel=0" title="${v.dataset.title || 'Video'}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>`;
    });
    v.appendChild(b);
  });

  // 세계지도: 브라이언/컬리지 스테이션 → 7개 선교지, 비행기가 선을 따라 오갑니다
  const map = document.getElementById('map');
  if (map) {
    const W = 1080, H = 402, LT = 76, LB = -58, VIEW = [150, 18, 855, 336];
    const xy = (lat, lon) => [(lon + 180) / 360 * W, (LT - lat) / (LT - LB) * H];
    const flag = c => String.fromCodePoint(...[...c].map(ch => 0x1F1E6 + ch.charCodeAt(0) - 65));
    const FIELDS = [['MX', 19.43, -99.13], ['EG', 30.04, 31.24], ['TH', 13.75, 100.5], ['MY', 3.14, 101.69], ['PH', 14.6, 120.98], ['KR', 37.57, 126.98], ['JP', 35.68, 139.69]];
    const FUTURE = [[14.63, -90.51], [18.49, -69.93], [4.71, -74.07], [-0.18, -78.47], [-12.05, -77.04], [-16.5, -68.15], [-15.79, -47.88], [-23.55, -46.63], [-33.45, -70.67], [-34.6, -58.38], [10.48, -66.9],
      [34.02, -6.83], [14.69, -17.44], [5.6, -0.19], [9.06, 7.49], [9.03, 38.74], [0.35, 32.58], [-1.29, 36.82], [-6.79, 39.21], [-4.32, 15.31], [-15.39, 28.32], [-25.75, 28.19], [-18.88, 47.51],
      [55.76, 37.62], [59.94, 30.31], [56.84, 60.6], [55.03, 82.92], [52.29, 104.3], [43.12, 131.9], [51.17, 71.45], [41.3, 69.24], [47.92, 106.92],
      [39.93, 32.86], [31.95, 35.93], [27.72, 85.32], [23.81, 90.41], [6.93, 79.86],
      [21.03, 105.85], [11.56, 104.92], [16.87, 96.2], [-6.21, 106.85], [-9.44, 147.18], [50.45, 30.52], [52.23, 21.01], [52.52, 13.4], [40.42, -3.7], [44.43, 26.1]];
    const [hx, hy] = xy(30.63, -96.33);
    const f = v => v.toFixed(1);
    const fut = FUTURE.map(([a, o], i) => { const [x, y] = xy(a, o); return `<circle class="future" cx="${f(x)}" cy="${f(y)}" r="3.4" style="--j:${i % 9}"/>`; }).join('');
    const PLANE = 'M7 0 L2.2 -1.1 L-1.2 -5.6 L-2.8 -5.6 L-1 -1.2 L-4.6 -1 L-6 -2.8 L-7 -2.8 L-6.2 0 L-7 2.8 L-6 2.8 L-4.6 1 L-1 1.2 L-2.8 5.6 L-1.2 5.6 L2.2 1.1 Z';
    const planes = [];
    const arcs = FIELDS.map(([c, a, o], i) => {
      const [x, y] = xy(a, o), dist = Math.hypot(x - hx, y - hy);
      const cx = (hx + x) / 2, cy = Math.max(VIEW[1] + 8, Math.min(hy, y) - Math.max(16, dist * 0.2));
      const dur = (3.2 + dist / 160).toFixed(1), st = (2.2 + i * 0.7).toFixed(1);
      planes.push(`<path id="lo${i}" d="M${f(hx)} ${f(hy)} Q${f(cx)} ${f(cy)} ${f(x)} ${f(y)}" fill="none"/><path id="lb${i}" d="M${f(x)} ${f(y)} Q${f(cx)} ${f(cy)} ${f(hx)} ${f(hy)}" fill="none"/>
        <g class="plane" opacity="0"><path class="plane-shape" d="${PLANE}"/><set attributeName="opacity" to="1" begin="${st}s" fill="freeze"/>
        <animateMotion id="po${i}" dur="${dur}s" begin="${st}s;pb${i}.end+0.6s" rotate="auto" fill="freeze"><mpath href="#lo${i}"/></animateMotion>
        <animateMotion id="pb${i}" dur="${dur}s" begin="po${i}.end+0.6s" rotate="auto" fill="freeze"><mpath href="#lb${i}"/></animateMotion></g>`);
      return `<path class="arc" d="M${f(hx)} ${f(hy)} Q${f(cx)} ${f(cy)} ${f(x)} ${f(y)}" pathLength="1" style="--i:${i}"/>
        <circle class="pin" cx="${f(x)}" cy="${f(y)}" r="4.2" style="--i:${i}"/><text class="pin-flag" x="${f(x)}" y="${f(y - 9)}" style="--i:${i}">${flag(c)}</text>`;
    }).join('');
    map.innerHTML = `<svg class="worldmap" viewBox="${VIEW.join(' ')}" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Map: from Bryan/College Station to seven mission fields, with more nations marked">
      <image href="${BASE}assets/world-dots.svg" x="0" y="0" width="${W}" height="${H}" class="dots"/>${fut}${arcs}${planes.join('')}
      <circle class="home-ring" cx="${f(hx)}" cy="${f(hy)}" r="10"/><circle class="home" cx="${f(hx)}" cy="${f(hy)}" r="5.2"/>
      <text class="home-label" x="${f(hx - 8)}" y="${f(hy + 22)}">Bryan/College Station</text></svg>`;
  }

  try { const saved = localStorage.getItem('svm_lang'); if (saved === 'ko' || (!saved && (navigator.language || '').startsWith('ko'))) setLang('ko'); } catch (e) {}
  // 스크롤 등장: 화면에 들어올 때 천천히 떠오르기 (IntersectionObserver, 움직임 줄이기 설정이면 생략)
  if ('IntersectionObserver' in window && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
    const groups = ['.s-head', '.mts', '.how', '.fields', '.feat-row', '.cards4', '.aud', '.night', '.rhythm', '.host-grid', '.faq', '.wwh', '.m-list', '.safety-grid'];
    const els = [];
    document.querySelectorAll(groups.join(',')).forEach(g => {
      const kids = g.matches('.s-head, .feat-row, .faq') ? [g] : [...g.children];
      kids.forEach((el, i) => { if (el.getBoundingClientRect().top > innerHeight) { el.classList.add('rv'); el.style.setProperty('--rv-d', Math.min(i, 5) * 0.07 + 's'); els.push(el); } });
    });
    const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    els.forEach(el => io.observe(el));
  }
})();
