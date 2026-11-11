/*
 * Service worker de LinkStack (PWA).
 *
 * Solo intercepta la página "/qr": la sirve desde caché al instante (funciona
 * sin conexión y aunque la sesión haya expirado) y la revalida en segundo plano.
 * El resto de la app pasa directo a la red, sin cambios.
 */
const QR_CACHE = 'linkstack-qr-v1';
const QR_PATH = '/qr';
const PRECACHE = [
  '/assets/linkstack/images/pwa/antares-logo-wide.png',
  '/assets/linkstack/images/pwa/icon-192.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(QR_CACHE).then((cache) => cache.addAll(PRECACHE)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k.startsWith('linkstack-qr-') && k !== QR_CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'logout') {
    event.waitUntil(caches.open(QR_CACHE).then((cache) => cache.delete(QR_PATH)));
  }
});

async function refreshQr(cache) {
  const response = await fetch(QR_PATH, { credentials: 'same-origin', cache: 'no-store' });
  // Una sesión expirada redirige al login: en ese caso se conserva el QR guardado
  if (response.ok && !response.redirected && response.type === 'basic') {
    await cache.put(QR_PATH, response.clone());
  }
  return response;
}

async function handleQr(event) {
  const cache = await caches.open(QR_CACHE);
  const cached = await cache.match(QR_PATH);

  if (cached) {
    event.waitUntil((async () => {
      try {
        const before = await cached.clone().text();
        const fresh = await refreshQr(cache);
        if (fresh.ok && !fresh.redirected && (await fresh.text()) !== before) {
          const clients = await self.clients.matchAll({ type: 'window' });
          clients.forEach((c) => c.postMessage({ type: 'qr-updated' }));
        }
      } catch (e) { /* sin conexión: queda el QR guardado */ }
    })());
    return cached;
  }

  try {
    return await refreshQr(cache);
  } catch (e) {
    return new Response(
      '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' +
      '<body style="font-family:sans-serif;display:grid;place-items:center;min-height:100vh;margin:0;text-align:center;padding:24px">' +
      '<p>Sin conexión. Abrí la app con internet al menos una vez para guardar tu QR.<br><br>' +
      'Offline. Open the app online once to save your QR code.</p></body>',
      { status: 503, headers: { 'Content-Type': 'text/html; charset=utf-8' } }
    );
  }
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  if (url.pathname === QR_PATH && req.mode === 'navigate') {
    event.respondWith(handleQr(event));
  } else if (PRECACHE.includes(url.pathname)) {
    event.respondWith(caches.match(url.pathname).then((hit) => hit || fetch(req)));
  }
});
