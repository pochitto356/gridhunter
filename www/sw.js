/* GRID HUNTER service worker — キャッシュ優先でオフライン動作 */
var CACHE = 'gridhunter-v5';
var ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-180.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './img/logo.png', './img/warning.png', './img/gridbreak.png',
  './img/boss_orbitron.png', './img/boss_blockcore.png', './img/boss_chaos.png',
  './img/player.png', './img/block_soft.png', './img/block_wall.png',
  './img/bullet_p.png', './img/bullet_e.png', './img/bullet_b.png',
  './img/en_grunt.png', './img/en_runner.png', './img/en_shooter.png',
  './img/en_bouncer.png', './img/en_bomber.png', './img/en_tank.png',
  './img/pu_power.png', './img/pu_rapid.png', './img/pu_spread.png', './img/pu_speed.png',
  './img/pu_pierce.png', './img/pu_heal.png', './img/pu_shield.png', './img/pu_bomb.png',
  './img/explosion_sheet.png'
];
self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(ASSETS); }).then(function () { return self.skipWaiting(); })
  );
});
self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});
self.addEventListener('fetch', function (e) {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(function (r) { return r || fetch(e.request); })
  );
});
