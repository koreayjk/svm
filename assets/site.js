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
    ft_l_contact: '문의', ft_legal: 'IM Mission Foundation Group Corp(EIN 99-2847865)는 501(c)(3) 비영리 단체입니다.',
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

  // 세계지도 (assets/worldmap.js): 아메리카가 가운데, 브라이언에서 비행기 5대가 선교지를 오감
  const map = document.getElementById('map');
  if (map && window.SVMWorldMap) {
    const wm = SVMWorldMap.mount(map, { base: BASE, lang: 'en', label: 'World map: SVM sends from Bryan/College Station to seven mission fields, with more nations marked.' });
    document.addEventListener('svm:lang', e => wm && wm.setLang(e.detail));
  }

  // 후원 버튼 — config.js 의 GIVING_URL 이 https 주소일 때만 보임 (그 전에는 기존 안내 문구가 보임)
  const giveUrl = (window.SVM_CONFIG || {}).GIVING_URL || '';
  if (/^https:\/\//.test(giveUrl)) {
    document.querySelectorAll('[data-give]').forEach(el => { el.hidden = false; if (el.tagName === 'A') { el.href = giveUrl; el.target = '_blank'; el.rel = 'noopener'; } });
    document.querySelectorAll('[data-give-off]').forEach(el => { el.hidden = true; });
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
