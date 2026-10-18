// SVM 세계지도 — 홈페이지 · 앱 로그인 화면 · 스토어 앱이 함께 씁니다.
//   · 아메리카가 가운데인 세계지도 한 장을 화면에 다 보여 줍니다.
//   · 브라이언/컬리지 스테이션에서 비행기 5대가
//     한 나라에 갔다가 돌아오고, 이어서 다른 나라로 갑니다. 날고 있는 길만 잠깐 그려집니다.
// 사용: SVMWorldMap.mount(element, { assets: '../assets/', lang: 'ko', label: '지도 설명' })  (assets: world-dots.svg 가 있는 폴더)
(function () {
  const W = 1080, H = 402, LT = 76, LB = -58;   // 점 지도(world-dots.svg, Natural Earth 기반) 좌표계
  const TOP = 18, VH = 336;                      // 보이는 영역: 위아래는 극지방을 조금 자름
  const CENTER_LON = -90;                        // 화면 가운데 경도 (아메리카)
  const LEFT_LON = CENTER_LON - 180;             // 화면 왼쪽 끝 경도

  // 보내는 곳
  const HUBS = {
    US: { lat: 30.63, lon: -96.33, en: 'Bryan/College Station', ko: '브라이언/컬리지 스테이션' },
  };
  // 지금 파송 중인 선교지
  const FIELDS = {
    MX: [19.43, -99.13], EG: [30.04, 31.24], TH: [13.75, 100.5], MY: [3.14, 101.69],
    PH: [14.6, 120.98], KR: [37.57, 126.98], JP: [35.68, 139.69],
  };
  // 비행기 5대의 일정: [출발 거점, 차례로 다녀올 나라들] — 한 나라에 갔다 오면 다음 나라로
  const FLIGHTS = [
    ['US', ['MX', 'EG', 'JP']],
    ['US', ['PH', 'TH', 'MY']],
    ['US', ['KR', 'MX', 'TH']],
    ['US', ['JP', 'MY', 'EG']],
    ['US', ['EG', 'PH', 'KR']],
  ];
  // 앞으로 갈 나라들 — 은은한 점
  const FUTURE = [
    [14.63, -90.51], [18.49, -69.93], [4.71, -74.07], [-0.18, -78.47], [-12.05, -77.04], [-16.5, -68.15],
    [-15.79, -47.88], [-23.55, -46.63], [-33.45, -70.67], [-34.6, -58.38], [10.48, -66.9],
    [34.02, -6.83], [14.69, -17.44], [5.6, -0.19], [9.06, 7.49], [9.03, 38.74], [0.35, 32.58],
    [-1.29, 36.82], [-6.79, 39.21], [-4.32, 15.31], [-15.39, 28.32], [-25.75, 28.19], [-18.88, 47.51],
    [55.76, 37.62], [59.94, 30.31], [56.84, 60.6], [55.03, 82.92], [52.29, 104.3], [43.12, 131.9],
    [51.17, 71.45], [41.3, 69.24], [47.92, 106.92],
    [39.93, 32.86], [31.95, 35.93], [27.72, 85.32], [23.81, 90.41], [6.93, 79.86],
    [21.03, 105.85], [11.56, 104.92], [16.87, 96.2], [-6.21, 106.85], [-9.44, 147.18],
    [50.45, 30.52], [52.23, 21.01], [52.52, 13.4], [40.42, -3.7], [44.43, 26.1],
  ];
  const PLANE = 'M7 0 L2.2 -1.1 L-1.2 -5.6 L-2.8 -5.6 L-1 -1.2 L-4.6 -1 L-6 -2.8 L-7 -2.8 L-6.2 0 L-7 2.8 L-6 2.8 L-4.6 1 L-1 1.2 L-2.8 5.6 L-1.2 5.6 L2.2 1.1 Z';

  // 아메리카가 가운데 오도록 경도를 돌린 좌표
  const xy = (lat, lon) => [(((lon - LEFT_LON) % 360) + 360) % 360 / 360 * W, (LT - lat) / (LT - LB) * H];
  const DOTS_SHIFT = (-180 - LEFT_LON) / 360 * W;   // 점 지도 그림을 옮길 거리
  const f = v => v.toFixed(1);
  const flag = c => String.fromCodePoint(...[...c].map(ch => 0x1F1E6 + ch.charCodeAt(0) - 65));

  function curve(from, to) {
    const [x1, y1] = xy(from[0], from[1]), [x2, y2] = xy(to[0], to[1]);
    const dist = Math.hypot(x2 - x1, y2 - y1);
    const cx = (x1 + x2) / 2, cy = Math.max(TOP + 10, Math.min(y1, y2) - Math.max(14, dist * 0.22));
    return { x1, y1, x2, y2, cx, cy, dist, d: `M${f(x1)} ${f(y1)} Q${f(cx)} ${f(cy)} ${f(x2)} ${f(y2)}` };
  }
  // 2차 베지어 위의 점과 진행 방향
  function at(c, t) {
    const u = 1 - t;
    const x = u * u * c.x1 + 2 * u * t * c.cx + t * t * c.x2, y = u * u * c.y1 + 2 * u * t * c.cy + t * t * c.y2;
    const dx = 2 * u * (c.cx - c.x1) + 2 * t * (c.x2 - c.cx), dy = 2 * u * (c.cy - c.y1) + 2 * t * (c.y2 - c.cy);
    return [x, y, Math.atan2(dy, dx) * 180 / Math.PI];
  }
  const ease = t => t < .5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;   // 이륙·착륙은 천천히

  function mount(el, opts = {}) {
    if (!el) return null;
    const lang = opts.lang === 'ko' ? 'ko' : 'en';
    const assets = opts.assets || (opts.base || '') + 'assets/';
    const fut = FUTURE.map(([a, o], i) => { const [x, y] = xy(a, o); return `<circle class="future" cx="${f(x)}" cy="${f(y)}" r="3.4" style="--j:${i % 9}"/>`; }).join('');
    const pins = Object.entries(FIELDS).filter(([c]) => !HUBS[c]).map(([c, [a, o]], i) => {
      const [x, y] = xy(a, o);
      return `<g class="field" data-c="${c}"><circle class="pin" cx="${f(x)}" cy="${f(y)}" r="4.2" style="--i:${i}"/><text class="pin-flag" x="${f(x)}" y="${f(y - 9)}" style="--i:${i}">${flag(c)}</text></g>`;
    }).join('');
    const hubs = Object.entries(HUBS).map(([code, h]) => {
      const [x, y] = xy(h.lat, h.lon);
      // 이름: 브라이언은 오른쪽 위(멕시코 국기와 안 겹치게)
      const [lx, ly, anchor] = code === 'US' ? [x + 9, y - 7, 'start'] : code === 'KR' ? [x, y - 27, 'middle'] : [x, y + 19, 'middle'];
      return `<g class="field hub" data-c="${code}"><circle class="home-ring" cx="${f(x)}" cy="${f(y)}" r="10"/><circle class="home" cx="${f(x)}" cy="${f(y)}" r="5.2"/>
        ${code !== 'US' ? `<text class="pin-flag hub-flag" x="${f(x)}" y="${f(y - 10)}">${flag(code)}</text>` : ''}
        <text class="home-label" text-anchor="${anchor}" data-en="${h.en}" data-ko="${h.ko}" x="${f(lx)}" y="${f(ly)}">${lang === 'ko' ? h.ko : h.en}</text></g>`;
    }).join('');
    const flights = FLIGHTS.map((_, i) => `<path class="trail" id="wm-trail-${i}" pathLength="1"/><g class="plane" id="wm-plane-${i}" opacity="0"><path class="plane-shape" d="${PLANE}"/></g>`).join('');
    el.style.aspectRatio = `${W} / ${VH}`;
    el.innerHTML = `<svg class="worldmap" viewBox="0 ${TOP} ${W} ${VH}" preserveAspectRatio="xMidYMid meet" role="img" aria-label="${(opts.label || '').replace(/"/g, '&quot;')}">
      <image href="${assets}world-dots.svg" x="${f(DOTS_SHIFT)}" y="0" width="${W}" height="${H}" class="dots"/>
      <image href="${assets}world-dots.svg" x="${f(DOTS_SHIFT - W)}" y="0" width="${W}" height="${H}" class="dots"/>
      ${fut}${flights}${pins}${hubs}</svg>`;
    const svg = el.firstChild;

    // 비행 일정 → 경로 목록
    const plans = FLIGHTS.map(([hub, dests]) => dests.map(c => {
      const h = HUBS[hub];
      return { to: c, c: curve([h.lat, h.lon], FIELDS[c]) };
    }));
    const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) {   // 움직임 줄이기: 비행기마다 첫 경로만 조용히 보여 줌
      plans.forEach((p, i) => { const tr = svg.querySelector(`#wm-trail-${i}`); tr.setAttribute('d', p[0].c.d); tr.style.strokeDashoffset = 0; tr.style.opacity = .6; });
      return api(svg);
    }

    // 비행기마다: 가는 길(선이 따라 그려짐) → 도착 잠깐 → 돌아오는 길(선이 뒤에서 지워짐) → 쉼 → 다음 나라
    const PAUSE = 700, REST = 900;
    const state = plans.map((p, i) => ({ k: 0, phase: 'wait', t0: performance.now() + 1400 + i * 1500 }));
    const els = plans.map((_, i) => ({ tr: svg.querySelector(`#wm-trail-${i}`), pl: svg.querySelector(`#wm-plane-${i}`) }));
    const dur = c => 2600 + c.dist * 4.2;
    const place = (e, c, t, back) => {
      const [x, y, a] = at(c, back ? 1 - t : t);
      e.pl.setAttribute('transform', `translate(${f(x)} ${f(y)}) rotate(${f(back ? a + 180 : a)})`);
    };
    const hit = code => {   // 도착한 나라 핀이 살짝 반짝
      const g = svg.querySelector(`.field[data-c="${code}"]`);
      if (!g) return;
      g.classList.remove('hit'); void g.getBBox(); g.classList.add('hit');
    };
    let raf = 0, alive = true;
    const step = now => {
      if (!alive || !svg.isConnected) return;
      state.forEach((s, i) => {
        const leg = plans[i][s.k], e = els[i], el2 = now - s.t0;
        if (s.phase === 'wait') { if (el2 >= 0) { s.phase = 'out'; s.t0 = now; e.tr.setAttribute('d', leg.c.d); e.tr.style.opacity = .9; e.pl.setAttribute('opacity', 1); } return; }
        if (s.phase === 'out') {
          const t = Math.min(1, el2 / dur(leg.c)), te = ease(t);
          e.tr.style.strokeDashoffset = 1 - te; place(e, leg.c, te, false);
          if (t >= 1) { s.phase = 'stay'; s.t0 = now; hit(leg.to); }
        } else if (s.phase === 'stay') {
          if (el2 >= PAUSE) { s.phase = 'back'; s.t0 = now; }
        } else if (s.phase === 'back') {
          const t = Math.min(1, el2 / dur(leg.c)), te = ease(t);
          e.tr.style.strokeDashoffset = te;   // 돌아오며 선을 거둠 (거점 ~ 비행기 사이만 남음)
          place(e, leg.c, te, true);
          if (t >= 1) { s.phase = 'rest'; s.t0 = now; e.pl.setAttribute('opacity', 0); e.tr.style.opacity = 0; }
        } else if (s.phase === 'rest' && el2 >= REST) {
          s.k = (s.k + 1) % plans[i].length; s.phase = 'wait'; s.t0 = now;
        }
      });
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    const a = api(svg);
    a.stop = () => { alive = false; cancelAnimationFrame(raf); };
    return a;
  }
  function api(svg) {
    return { setLang(l) { svg.querySelectorAll('.home-label').forEach(t => { t.textContent = t.dataset[l === 'ko' ? 'ko' : 'en']; }); } };
  }

  window.SVMWorldMap = { mount, HUBS, FIELDS, FLIGHTS };
})();
