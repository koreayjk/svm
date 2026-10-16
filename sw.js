// SVM service worker — 앱 셸 캐시 (Supabase 등 외부 요청은 항상 네트워크)
// index.html 을 수정해 배포할 때 VERSION 을 올리면 이전 캐시가 정리됩니다.
const VERSION = 'svm-v9';
const SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './assets/SVM_Logo.svg',
  './assets/SVM_Logo_white.svg',
  './assets/countries/kr.jpg',
  './assets/countries/ph.jpg',
  './assets/countries/my.jpg',
  './assets/countries/th.jpg',
  './assets/countries/mx.jpg',
  './assets/countries/jp.jpg',
  './assets/countries/eg.jpg',
  './icons/icon.svg',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/apple-touch-icon.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // 페이지: 네트워크 우선 (새 버전 즉시 반영), 오프라인이면 캐시
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then((res) => {
          if (res.ok) { const copy = res.clone(); caches.open(VERSION).then((c) => c.put('./index.html', copy)); }
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }
  // 정적 파일: 캐시 우선
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
