/* Service worker — Mon budget (PWA)
   Stratégie : "réseau d'abord" pour la page (toujours la dernière version quand il y a du réseau),
   bascule sur le cache hors-ligne. Les autres fichiers de l'app sont mis en cache. */
const CACHE = "monbudget-v1";
const ASSETS = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icon-192.png",
  "./icon-512.png",
  "./apple-touch-icon.png"
];

self.addEventListener("install", e => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS).catch(() => {})));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Laisser passer ce qui n'est pas sur notre domaine (Supabase, CDN) — réseau direct
  if (url.origin !== location.origin) return;

  const isHTML = req.mode === "navigate" || (req.headers.get("accept") || "").includes("text/html");
  if (isHTML) {
    // Réseau d'abord : la page est toujours à jour quand il y a du réseau
    e.respondWith(
      fetch(req)
        .then(res => { const cp = res.clone(); caches.open(CACHE).then(c => c.put(req, cp)); return res; })
        .catch(() => caches.match(req).then(r => r || caches.match("./index.html")))
    );
    return;
  }
  // Autres fichiers : cache d'abord, réseau sinon
  e.respondWith(
    caches.match(req).then(r => r || fetch(req).then(res => {
      const cp = res.clone(); caches.open(CACHE).then(c => c.put(req, cp)); return res;
    }))
  );
});
