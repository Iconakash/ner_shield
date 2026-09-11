import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_manager.dart';
import '../core/drafts/draft_repository.dart';
import '../core/drafts/media_queue.dart';
import '../core/location/geolocator_location_service.dart';
import '../core/maps/offline_tile_cache.dart';
import '../core/maps/offline_tile_fetcher.dart';
import '../core/location/gps_ping_beacon.dart';
import '../core/location/last_known_location_store.dart';
import '../core/location/location_service.dart';
import '../core/network/api_client.dart';
import '../core/risk/offline_risk.dart';
import '../core/risk/offline_risk_store.dart';
import '../core/storage/secure_token_storage.dart';
import '../core/sync/persistent_sync_queue_storage.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_queue_database.dart';
import '../repositories/accessibility_repository.dart';
import '../repositories/alerts_repository.dart';
import '../repositories/command_repository.dart';
import '../repositories/field_reports_repository.dart';
import '../repositories/gis_repository.dart';
import '../repositories/historical_repository.dart';
import '../repositories/notifications_repository.dart';
import '../repositories/responder_repository.dart';
import '../repositories/risk_repository.dart';
import '../repositories/routing_repository.dart';
import '../repositories/shipments_repository.dart';
import '../repositories/tasks_repository.dart';
import '../services/accessibility_service.dart';
import '../services/alerts_service.dart';
import '../services/command_service.dart';
import '../services/field_reports_service.dart';
import '../services/gis_service.dart';
import '../services/historical_service.dart';
import '../services/notifications_service.dart';
import '../services/responder_service.dart';
import '../services/risk_service.dart';
import '../services/routing_service.dart';
import '../services/shipments_service.dart';
import '../services/sync_service.dart';
import '../services/tasks_service.dart';

/// Client configuration (only client-safe values — see docs/security-plan.md).
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.defaults());

/// Platform keystore-backed token storage.
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage.platform();
});

/// Global callback invoked when the shared Dio observes a 401. Registered by
/// `AuthController.build()`; `null` in tests/edge cases means no-op.
final sessionExpiryHandlerProvider =
    StateProvider<Future<void> Function()?>((ref) => null);

// --------------------------------------------------------- endpoint services
// Stateless wrappers around the shared Dio (single API client — master
// prompt §18: no duplicate HTTP systems). Auth lives in
// features/auth/auth_controller.dart (authServiceProvider).

final commandServiceProvider =
    Provider<CommandService>((ref) => CommandService(ref.watch(dioProvider)));

final riskServiceProvider =
    Provider<RiskService>((ref) => RiskService(ref.watch(dioProvider)));

final accessibilityServiceProvider = Provider<AccessibilityService>(
    (ref) => AccessibilityService(ref.watch(dioProvider)));

final alertsServiceProvider =
    Provider<AlertsService>((ref) => AlertsService(ref.watch(dioProvider)));

final shipmentsServiceProvider = Provider<ShipmentsService>(
    (ref) => ShipmentsService(ref.watch(dioProvider)));

final syncServiceProvider =
    Provider<SyncService>((ref) => SyncService(ref.watch(dioProvider)));

final gisServiceProvider =
    Provider<GisService>((ref) => GisService(ref.watch(dioProvider)));

final routingServiceProvider =
    Provider<RoutingService>((ref) => RoutingService(ref.watch(dioProvider)));

final historicalServiceProvider = Provider<HistoricalService>(
    (ref) => HistoricalService(ref.watch(dioProvider)));

final responderServiceProvider = Provider<ResponderService>(
    (ref) => ResponderService(ref.watch(dioProvider)));

final tasksServiceProvider = Provider<TasksService>(
    (ref) => TasksService(ref.watch(dioProvider)));

final fieldReportsServiceProvider = Provider<FieldReportsService>(
    (ref) => FieldReportsService(ref.watch(dioProvider)));

// ---------------------------------------------------------------- repositories
// Cache-first reads (TtlCache + stale fallback when offline).

final commandRepositoryProvider = Provider<CommandRepository>(
    (ref) => CommandRepository(ref.watch(commandServiceProvider)));

final riskRepositoryProvider = Provider<RiskRepository>(
    (ref) => RiskRepository(
          ref.watch(riskServiceProvider),
          // Phase 6 — persistent last-known risk snapshot (§6.1-6.2).
          offlineStore: OfflineRiskStore(ref.watch(syncQueueDatabaseProvider)),
        ));

/// Phase 6 — last synchronised risk snapshot with explicit freshness
/// metadata, surfaced as the degraded-data banner on the risk screen
/// (null until the device has synchronised at least once).
final offlineRiskSnapshotProvider =
    FutureProvider<OfflineRiskResult?>((ref) async {
  final repo = ref.watch(riskRepositoryProvider);
  return repo.offlineSnapshot();
});

final accessibilityRepositoryProvider = Provider<AccessibilityRepository>(
    (ref) => AccessibilityRepository(ref.watch(accessibilityServiceProvider)));

final alertsRepositoryProvider = Provider<AlertsRepository>(
    (ref) => AlertsRepository(ref.watch(alertsServiceProvider)));

final shipmentsRepositoryProvider = Provider<ShipmentsRepository>(
    (ref) => ShipmentsRepository(ref.watch(shipmentsServiceProvider)));

final gisRepositoryProvider = Provider<GisRepository>(
    (ref) => GisRepository(ref.watch(gisServiceProvider)));

final fieldReportsRepositoryProvider = Provider<FieldReportsRepository>(
    (ref) => FieldReportsRepository(
      ref.watch(fieldReportsServiceProvider),
      // Phase 2 — wire the persistent draft repository backed by the
      // same Drift database as the sync queue.
      drafts: ref.watch(draftRepositoryProvider),
    ));

final notificationsServiceProvider = Provider<NotificationsService>(
    (ref) => NotificationsService(ref.watch(dioProvider)));

/// Preferences are always-fresh reads (no cache) — see the repository docs.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(ref.watch(notificationsServiceProvider)));

final routingRepositoryProvider = Provider<RoutingRepository>(
    (ref) => RoutingRepository(
          ref.watch(routingServiceProvider),
          // Phase 5 — offline routing snapshot backed by the shared Drift DB.
          offlineStore:
              OfflineRouteGraphStore(ref.watch(syncQueueDatabaseProvider)),
        ));

final historicalRepositoryProvider = Provider<HistoricalRepository>(
    (ref) => HistoricalRepository(ref.watch(historicalServiceProvider)));

final responderRepositoryProvider = Provider<ResponderRepository>(
    (ref) => ResponderRepository(ref.watch(responderServiceProvider)));

final tasksRepositoryProvider = Provider<TasksRepository>(
    (ref) => TasksRepository(ref.watch(tasksServiceProvider)));

// --------------------------------------------------------- Phase 1+2 sync DB
// The shared Drift database backing the sync queue, drafts, and media.
// Production overrides this at app boot (lib/main.dart). The default
// backend lets existing tests run without a platform channel.
final syncQueueDatabaseProvider = Provider<SyncQueueDatabase>((ref) {
  return SyncQueueDatabase.memory();
});

/// Phase 2 — persistent draft repository. Backed by the same Drift DB
/// as the sync queue.
final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return DraftRepository(ref.watch(syncQueueDatabaseProvider));
});

/// Phase 2 — media upload registry.
final mediaQueueProvider = Provider<MediaQueue>((ref) {
  return MediaQueue(ref.watch(syncQueueDatabaseProvider));
});

// --------------------------------------------------------- Phase 3 GPS
// Phase 3 — phone GPS abstraction. Production wires
// [GeolocatorLocationService] at app boot; tests override with
// [MockLocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

/// Phase 3 — persistent last-known-fix store (Drift-backed).
final lastKnownLocationStoreProvider =
    Provider<LastKnownLocationStore>((ref) {
  return LastKnownLocationStore(ref.watch(syncQueueDatabaseProvider));
});

/// Phase 3 — beacon that turns GPS fixes into GPS_PING queue ops.
/// Active only when the user has granted permission AND the OS-level
/// GPS service is enabled. The shared `autoSyncOnReconnectProvider`
/// (Phase 1) flushes the queue on reconnect — no extra wiring needed.
final gpsPingBeaconProvider = Provider<GpsPingBeacon>((ref) {
  final beacon = GpsPingBeacon(
    location: ref.watch(locationServiceProvider),
    queue: ref.watch(syncQueueProvider),
    store: ref.watch(lastKnownLocationStoreProvider),
  );
  ref.onDispose(() async {
    await beacon.stop();
  });
  return beacon;
});

// --------------------------------------------------------- Phase 4 tile cache
// Phase 4 — offline map raster tile cache. Backed by the same Drift
// database as the sync queue, drafts, media, and last-known GPS.
final offlineTileCacheProvider = Provider<OfflineTileCache>((ref) {
  return OfflineTileCache(ref.watch(syncQueueDatabaseProvider));
});

/// Phase 4 — single shared tile fetcher wired to the OSM tile template.
/// The connectivity stream is read lazily at fetch time (no manual
/// listening) so the moment the device goes OFFLINE the fetcher serves
/// cache-only — no network attempt, no hang.
final offlineTileFetcherProvider = Provider<OfflineTileFetcher>((ref) {
  final cache = ref.watch(offlineTileCacheProvider);
  final config = ref.watch(appConfigProvider);
  final fetcher = OfflineTileFetcher(
    cache: cache,
    urlTemplate: config.outboundTileUrl,
    isOffline: () => ref.read(connectivityClassProvider) == 'OFFLINE',
  );
  ref.onDispose(fetcher.dispose);
  return fetcher;
});

/// Phase 4 — read-only cache summary for the map's offline banner
/// (tiles cached, bytes used, data age). Recomputed when the OfflineTileCache
/// emits a new snapshot.
final offlineMapStatsProvider =
    FutureProvider<OfflineTileCacheSummary>((ref) async {
  final cache = ref.watch(offlineTileCacheProvider);
  final config = ref.watch(appConfigProvider);
  final templateHash = OfflineTileCache.hashForTemplate(config.outboundTileUrl);
  final tiles = await cache.tileCount(templateHash);
  final bytes = await cache.totalBytes(templateHash);
  final last = await cache.lastUpdatedAt(templateHash);
  return OfflineTileCacheSummary(
    tilesCached: tiles,
    bytesCached: bytes,
    bytesBudget: cache.config.maxBytes,
    templateHash: templateHash,
    lastUpdated: last,
  );
});

/// Phase 1 — singleton sync queue, exported here so other providers can
/// wire it without depending on features/incidents/sync_controller.
final syncQueueProvider = Provider<SyncQueue>((ref) {
  final db = ref.watch(syncQueueDatabaseProvider);
  final storage = PersistentSyncQueueStorage(db);
  final queue = SyncQueue(storage: storage);
  ref.onDispose(queue.dispose);
  return queue;
});