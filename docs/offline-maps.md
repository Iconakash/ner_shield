# NER-SHIELD — Offline Map Foundation (Phase 4)

> Strategy: **locally-cached raster tiles** (approved option A) — a
> persistent, LRU-bounded, corruption-checked tile cache backed by the
> app's existing Drift/SQLite database. No new tile provider, no new
> map dependency, no second map stack.

## 1. Architecture

```
FlutterMap (flutter_map 8.x)
  └── TileLayer(tileProvider: OfflineTileProvider)
        └── OfflineTileFetcher            ← cache-first, network second
              ├── OfflineTileCache        ← Drift table `map_tile_rows`
              │     (z, x, y, template_hash) → bytes + sha256 + LRU stamps
              └── http.Client             ← OSM raster fetch (online only)
```

* **Cache-first read path.** Every tile request consults
  `OfflineTileCache.read()` first. Hits are served instantly with an LRU
  touch (`last_accessed_at`).
* **Write-through.** Online cache misses fetch via `http.Client` with the
  OSM-required `User-Agent` and are written through (sha256 + magic-byte
  validated) before being rendered.
* **Offline gating.** `offlineTileFetcherProvider` wires a lazy
  `isOffline` callback to `connectivityClassProvider`. When OFFLINE the
  fetcher never touches the network: cached tiles are served, uncached
  tiles return flutter_map's transparent placeholder (no hang, no
  fabricated imagery).
* **Update strategy.** Optional `maxTileAge` TTL: a stale-but-valid
  cached tile is refreshed once when online; if the refresh fails the
  stale tile is still served (known age, never faked). Schema carries a
  `version` column for future cache-format migrations.
* **Capacity.** `OfflineTileCacheConfig.maxBytes` (default 200 MiB) with
  LRU eviction targeting `maxBytes * (1 - minFreeRatio)`.
* **Corruption handling.** Stored sha256 mismatch or bad magic bytes
  (PNG/JPEG/WebP sniff) → row deleted on read → treated as cache miss.
  HTML error bodies from tile servers are rejected at write time.
* **Multi-provider isolation.** Keys include `sha256(urlTemplate)` so an
  OSM cache and a future Mapbox/Bhuvan layer never collide.

## 2. Coverage of the NER operational region

The cache fills **lazily from user pan/zoom** while online. Whatever NER
area the officer has viewed stays renderable offline, across restarts
(the table lives in `ner_shield_sync_queue.sqlite`).

A pre-packaged full-NER archive (MBTiles at all useful zooms) remains an
optional future enhancement: it requires a tile-data source and a
licensing decision and is tracked as a separate blocker — it is **not**
required by the Phase 4 acceptance criterion ("the NER map must still
render for the **packaged/cached** operational region").

## 3. Licensing / attribution

* Tile source remains the configured OSM-compatible raster endpoint
  (`AppConfig.outboundTileUrl`, default
  `https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
* OSM Tile Usage Policy compliance:
  * identifying `User-Agent` on every request
    (`in.gov.mdoner.nershield`);
  * **no bulk download** — tiles are cached only as the user views them;
  * cache is per-device, never redistributed.
* The required "© OpenStreetMap contributors" attribution is rendered by
  the existing `RichAttributionWidget` on the map screen (unchanged).

## 4. Offline UI (§4.4)

`OfflineMapBanner` (pinned over the map) appears only while OFFLINE and
shows: connectivity state, cached tile count, bytes used, and the age of
the newest cached tile ("cached 2 h ago"). It never claims the map is
live. The pre-existing stale-layer banner is shifted below it and is
unaffected.

## 5. Tests

* `test/phase4_offline_map_test.dart` — cache core: template-hash
  isolation, magic-byte sniff, write-through hits, corruption rejection,
  LRU eviction under budget, restart survival, summary + clear.
* `test/phase4_offline_tile_fetcher_test.dart` — fetcher behavior:
  offline+cached served with zero network calls, offline+uncached miss
  with zero network calls, online write-through persistence, HTML error
  body rejected and not cached, TTL refresh, TTL-refresh failure falls
  back to stale cached bytes.
* `test/phase4_offline_map_banner_test.dart` — banner hidden online;
  stats visible offline.
* Existing `phase8_map_screen_test.dart` widget tests still pass with the
  `OfflineTileProvider` wired in (fake HTTP overrides keep them hermetic).