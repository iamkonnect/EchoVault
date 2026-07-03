'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "2ae17aae9b44548b100722b82216dbcf",
"assets/AssetManifest.bin.json": "4c1b1ecb3fc6080b096f6f73b18d7567",
"assets/AssetManifest.json": "11bc216d28eca42a591afca0d03ec346",
"assets/assets/appicon.svg": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/assets/featured_echo_1.jpeg": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/Echo-Vault-Icon.png": "2677c2b3d4576699a10ce48e456b1cec",
"assets/assets/samples/album-jpegmafia.jpg": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/samples/album-pushat.jpg": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/samples/album-smino.jpg": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/samples/README.md": "f8d15534f9e28a0d49704638816df6ae",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.45%2520(1).jpeg": "f60d391219921fb9fea861e4cde5d703",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.45%2520(2).jpeg": "7232680496ee353a019a3da9c09b99b9",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.45%2520(3).jpeg": "2f5245e16f80f82ee5f6d7447c4061e8",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.45.jpeg": "54a595f1349280fcd1217c38d7a7acd9",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(1).jpeg": "a2e343a78c8b4f6d26370dcf0e5d4237",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(10).jpeg": "c42d24b874a5f802d4723dfa30e48d15",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(11).jpeg": "4bebabb4db9cbab8efcaa5fce19ff082",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(12).jpeg": "4bebabb4db9cbab8efcaa5fce19ff082",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(13).jpeg": "cbf2cc76efae763923d674d41434f7f4",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(14).jpeg": "92995bbc09ae20bfe380525b133baab6",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(15).jpeg": "aa2a2259f7e50a59a378ee54b2a8d55e",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(16).jpeg": "0621c9b435aab2bb583500426e32b7ee",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(17).jpeg": "4de08a07b7ff32b66525858f168a23b1",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(18).jpeg": "f0ae1596b27aeaee021f6ad6051df107",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(19).jpeg": "42498ad86e5350e1c1e0608495a3ee91",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(2).jpeg": "2f55bd3996f6467cc4460bf5952d6b1e",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(20).jpeg": "5a9a35323254500d5a74f3a6e8adea9e",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(21).jpeg": "05ddffc3a886ae10d31550c7550425d1",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(22).jpeg": "0f0f5f783b3785dac4a0594242a4e52e",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(23).jpeg": "16a234fa4a06755cf900a4c9323ac186",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(24).jpeg": "45975a3ccc208fac929f72e6b54b4227",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(25).jpeg": "f9fc37f137877e9710d04d9ddcf49fcc",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(26).jpeg": "cc7e911ccf67ea4900998a77c0aa3a05",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(27).jpeg": "6e952f8717ca2257aa520470c6cc33b2",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(28).jpeg": "53df38abe64000e8918c0097893b5b44",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(29).jpeg": "d0be4325db98a85ea2073b575df83244",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(3).jpeg": "87727b9dc668a7dbc28146c1653cce7f",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(30).jpeg": "6e69300dcf4fdbb8c42cc6197909cf1f",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(31).jpeg": "516b8833e4a93ca4360a98756499c70f",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(32).jpeg": "4c76344facfe0d210677bb5a109b8e7f",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(4).jpeg": "80c6b7b668591518661c74ebb287fc07",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(5).jpeg": "3afc26d24295b0c0bde04d679d59d35d",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(6).jpeg": "58867b1db4c296d62f3f0927f9930b91",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(7).jpeg": "e55ab2d06036ca616649cbc2f93c1bdd",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(8).jpeg": "7ef4a3cb1f901d27ff1f460ead500514",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46%2520(9).jpeg": "877067d107069bb0d00f3584938a8cba",
"assets/assets/WhatsApp%2520Image%25202026-03-17%2520at%252013.04.46.jpeg": "c5506acdb1707f095f7c2482d14c8248",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "dbbf719406bdb094fb31f4b517fad08c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "2677c2b3d4576699a10ce48e456b1cec",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "ba6baa4735383f769a2fbd74ac51d731",
"icons/Echo-Vault-Icon.png": "2677c2b3d4576699a10ce48e456b1cec",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "ff7d11a293ac30cfb18b0309c8665a72",
"/": "ff7d11a293ac30cfb18b0309c8665a72",
"main.dart.js": "eb1071d8670efc119a4605fa58897a03",
"manifest.json": "a2945cbdce255d50c627bead3c69905e",
"service_worker.js": "ff129adca045efde4904cc8d097fa443",
"version.json": "564990b5c9c5601eeba93b9342fa8d9a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
