// SVM 세계지도 — 홈페이지 · 앱 로그인 화면 · 스토어 앱이 함께 씁니다.
//   · 아메리카가 가운데. 좌우로 끌면 지구가 끝없이 이어져 돌아갑니다 (손을 떼면 관성으로 미끄러짐).
//   · 보내는 곳 3곳(브라이언/컬리지 스테이션 · 서울 · 마닐라)에서 선교지로 선이 이어지고 비행기가 오갑니다.
// 사용: SVMWorldMap.mount(element, { assets: '../assets/', lang: 'ko', label: '지도 설명' })  (assets: world-dots.svg 가 있는 폴더)
(function () {
  const W = 1080, H = 402, LT = 76, LB = -58;   // 점 지도(world-dots.svg, Natural Earth 기반) 좌표계
  const TOP = 18, VH = 336;                      // 보이는 영역: 위아래는 극지방을 조금 자름
  // 가로: 넓은 화면은 지구 한 바퀴 전체, 좁은 화면(폰)은 2/3 크게 — 나머지는 끌어서
  const CENTER_LON = -88;                        // 처음 화면 가운데 (아메리카)

  // 보내는 곳 — 여기서 출발하는 선이 그려집니다. 새 거점이 생기면 한 줄 추가하세요.
  const HUBS = [
    { code: 'US', lat: 30.63, lon: -96.33, en: 'Bryan/College Station', ko: '브라이언/컬리지 스테이션' },
    { code: 'KR', lat: 37.57, lon: 126.98, en: 'Seoul', ko: '서울' },
    { code: 'PH', lat: 14.6, lon: 120.98, en: 'Manila', ko: '마닐라' },
  ];
  // 지금 파송 중인 선교지 — 핀 + 국기
  const FIELDS = [
    ['MX', 19.43, -99.13], ['EG', 30.04, 31.24], ['TH', 13.75, 100.5], ['MY', 3.14, 101.69],
    ['PH', 14.6, 120.98], ['KR', 37.57, 126.98], ['JP', 35.68, 139.69],
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

  const xy = (lat, lon) => [(lon + 180) / 360 * W, (LT - lat) / (LT - LB) * H];
  const f = v => v.toFixed(1);
  const flag = c => String.fromCodePoint(...[...c].map(ch => 0x1F1E6 + ch.charCodeAt(0) - 65));

  // 거점 → 선교지 경로 (같은 나라는 빼고, 서울↔마닐라는 한 번만)
  const ROUTES = [];
  HUBS.forEach(h => FIELDS.forEach(([code, lat, lon]) => {
    if (code === h.code) return;
    if (h.code === 'PH' && code === 'KR') return;
    const [x1, y1] = xy(h.lat, h.lon);
    let [x2, y2] = xy(lat, lon);
    // 가까운 쪽으로 (예: 브라이언 → 서울은 태평양을 건너 서쪽으로)
    if (x2 - x1 > W / 2) x2 -= W; else if (x1 - x2 > W / 2) x2 += W;
    const dist = Math.hypot(x2 - x1, y2 - y1);
    const cx = (x1 + x2) / 2, cy = Math.max(TOP + 8, Math.min(y1, y2) - Math.max(14, dist * 0.2));
    ROUTES.push({ hub: h.code, x1, y1, x2, y2, cx, cy, dist });
  }));

  // 지구 한 바퀴 분량 — 좌우로 세 번 이어 붙여 끝없이 돌아가게 합니다
  function tile(k, uid, lang) {
    const id = `${uid}-${k + 1}`;
    const planes = [];
    const arcs = ROUTES.map((r, i) => {
      const d = `M${f(r.x1)} ${f(r.y1)} Q${f(r.cx)} ${f(r.cy)} ${f(r.x2)} ${f(r.y2)}`;
      // 비행기는 절반의 경로에만 (화면이 복잡하지 않게)
      if (i % 2 === 0) {
        const back = `M${f(r.x2)} ${f(r.y2)} Q${f(r.cx)} ${f(r.cy)} ${f(r.x1)} ${f(r.y1)}`;
        const dur = (3.4 + r.dist / 150).toFixed(1), st = (2.2 + (i / 2) * 0.55).toFixed(2);
        planes.push(`<path id="${id}o${i}" d="${d}" fill="none" stroke="none"/><path id="${id}b${i}" d="${back}" fill="none" stroke="none"/>
          <g class="plane" opacity="0"><path class="plane-shape" d="${PLANE}"/><set attributeName="opacity" to="1" begin="${st}s" fill="freeze"/>
          <animateMotion id="${id}po${i}" dur="${dur}s" begin="${st}s;${id}pb${i}.end+0.6s" rotate="auto" fill="freeze"><mpath href="#${id}o${i}"/></animateMotion>
          <animateMotion id="${id}pb${i}" dur="${dur}s" begin="${id}po${i}.end+0.6s" rotate="auto" fill="freeze"><mpath href="#${id}b${i}"/></animateMotion></g>`);
      }
      return `<path class="arc arc-${r.hub.toLowerCase()}" d="${d}" pathLength="1" style="--i:${i % 9}"/>`;
    }).join('');
    const fut = FUTURE.map(([a, o], i) => { const [x, y] = xy(a, o); return `<circle class="future" cx="${f(x)}" cy="${f(y)}" r="3.4" style="--j:${i % 9}"/>`; }).join('');
    const pins = FIELDS.filter(([c]) => !HUBS.some(h => h.code === c)).map(([c, a, o], i) => {
      const [x, y] = xy(a, o);
      return `<circle class="pin" cx="${f(x)}" cy="${f(y)}" r="4.2" style="--i:${i}"/><text class="pin-flag" x="${f(x)}" y="${f(y - 9)}" style="--i:${i}">${flag(c)}</text>`;
    }).join('');
    // 거점: 남색 점 + 퍼지는 고리 + 국기 + 도시 이름 (거점이면서 선교지인 한국·필리핀도 여기서)
    const hubs = HUBS.map(h => {
      const [x, y] = xy(h.lat, h.lon);
      // 이름 위치: 브라이언은 오른쪽 위(아래의 멕시코 국기와 안 겹치게), 서울은 국기 위, 마닐라는 아래
      const [lx, ly, anchor] = h.code === 'US' ? [x + 9, y - 7, 'start'] : h.code === 'KR' ? [x, y - 27, 'middle'] : [x, y + 19, 'middle'];
      return `<circle class="home-ring" cx="${f(x)}" cy="${f(y)}" r="10"/><circle class="home" cx="${f(x)}" cy="${f(y)}" r="5.2"/>
        ${h.code !== 'US' ? `<text class="pin-flag hub-flag" x="${f(x)}" y="${f(y - 10)}">${flag(h.code)}</text>` : ''}
        <text class="home-label" text-anchor="${anchor}" data-en="${h.en}" data-ko="${h.ko}" x="${f(lx)}" y="${f(ly)}">${lang === 'ko' ? h.ko : h.en}</text>`;
    }).join('');
    return `<g transform="translate(${k * W} 0)">
      <image href="__ASSETS__world-dots.svg" x="0" y="0" width="${W}" height="${H}" class="dots"/>
      ${fut}${arcs}${planes.join('')}${pins}${hubs}</g>`;
  }

  let seq = 0;
  function mount(el, opts = {}) {
    if (!el) return null;
    const uid = 'wm' + (++seq);
    const lang = opts.lang === 'ko' ? 'ko' : 'en';
    const VW = (el.clientWidth || innerWidth) < 600 ? 720 : W;
    el.style.aspectRatio = `${VW} / ${VH}`;
    const svgTiles = [-1, 0, 1].map(k => tile(k, uid, lang)).join('').replace(/__ASSETS__/g, opts.assets || (opts.base || '') + 'assets/');
    el.innerHTML = `<svg class="worldmap draggable" viewBox="0 ${TOP} ${VW} ${VH}" preserveAspectRatio="xMidYMid meet" role="img" tabindex="0" aria-label="${(opts.label || '').replace(/"/g, '&quot;')}">${svgTiles}</svg>`;
    const svg = el.firstChild;
    const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

    // ---- 좌우로 돌리기 (손가락을 그대로 따라가고, 놓으면 그 속도로 미끄러지다 멈춤) ----
    let x0 = 0, raf = 0, drag = null;
    const norm = x => ((x % W) + W) % W - W;   // 항상 [-W, 0) — 세 장의 지도 안에서만 움직이게
    const set = x => { x0 = norm(x); svg.setAttribute('viewBox', `${f(x0)} ${TOP} ${VW} ${VH}`); };
    const unit = () => VW / (svg.getBoundingClientRect().width || VW);   // 화면 1px = 지도 몇 칸
    set(xy(0, CENTER_LON)[0] - VW / 2);

    const glide = v => {   // v: 지도 칸 / ms
      cancelAnimationFrame(raf);
      if (reduce) return;
      let last = performance.now();
      const step = now => {
        const dt = Math.min(40, now - last); last = now;
        set(x0 + v * dt);
        v *= Math.pow(0.994, dt);   // 마찰
        if (Math.abs(v) > 0.004) raf = requestAnimationFrame(step);
      };
      raf = requestAnimationFrame(step);
    };
    svg.addEventListener('pointerdown', e => {
      if (e.button) return;
      cancelAnimationFrame(raf);
      drag = { id: e.pointerId, x: e.clientX, hist: [[e.clientX, e.timeStamp]], moved: false };
      svg.setPointerCapture(e.pointerId);
      svg.classList.add('grabbing');
    });
    svg.addEventListener('pointermove', e => {
      if (!drag || e.pointerId !== drag.id) return;
      const dx = e.clientX - drag.x;
      if (Math.abs(dx) > 0) { set(x0 - dx * unit()); drag.moved = true; }
      drag.x = e.clientX;
      drag.hist.push([e.clientX, e.timeStamp]);
      if (drag.hist.length > 6) drag.hist.shift();
    });
    const end = e => {
      if (!drag || e.pointerId !== drag.id) return;
      const h = drag.hist, a = h[0], b = h[h.length - 1];
      const dt = b[1] - a[1];
      svg.classList.remove('grabbing');
      if (drag.moved && dt > 0 && e.timeStamp - b[1] < 80) glide(-(b[0] - a[0]) / dt * unit());
      drag = null;
    };
    svg.addEventListener('pointerup', end);
    svg.addEventListener('pointercancel', end);
    // 트랙패드 가로 스크롤 · 키보드 화살표
    svg.addEventListener('wheel', e => {
      if (Math.abs(e.deltaX) <= Math.abs(e.deltaY)) return;
      e.preventDefault(); cancelAnimationFrame(raf); set(x0 + e.deltaX * unit());
    }, { passive: false });
    svg.addEventListener('keydown', e => {
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
      e.preventDefault(); glide((e.key === 'ArrowLeft' ? -1 : 1) * 0.6);
    });
    return {
      setLang(l) { svg.querySelectorAll('.home-label').forEach(t => { t.textContent = t.dataset[l === 'ko' ? 'ko' : 'en']; }); },
    };
  }

  window.SVMWorldMap = { mount, HUBS, FIELDS };
})();
