import 'package:drift/drift.dart';

import 'database_factory.dart';
import 'in_memory_executor_native.dart'
    if (dart.library.html) 'in_memory_executor_web.dart';

part 'sync_queue_database.g.dart';

// ignore_for_file: unused_element_parameter

/// One row per queued offline op. Mirrors `SyncQueueEntry`.
@DataClassName('SyncQueueRow')
class SyncQueueRows extends Table {
  TextColumn get clientOpId => text()();
  TextColumn get opType => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get lastAttemptAt => text().nullable()();
  TextColumn get nextRetryAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get resourceId => text().nullable()();
  TextColumn get dependencyClientOpId => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientOpId};
}

/// Append-only attempt history.
@DataClassName('SyncAttemptRow')
class SyncAttemptRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientOpId => text()();
  IntColumn get attempt => integer()();
  TextColumn get at => text()();
  TextColumn get outcome => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get resourceId => text().nullable()();
}

/// Phase 2 — persisted field-report drafts. Survives app kill.
@DataClassName('DraftRow')
class DraftRows extends Table {
  TextColumn get clientDraftId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientDraftId};
}

/// Phase 2 — media refs persisted alongside drafts + queue. Lets the
/// upload worker resume after a process restart.
@DataClassName('DraftMediaRow')
class DraftMediaRows extends Table {
  TextColumn get clientRefId => text()();
  TextColumn get clientDraftId => text()();
  TextColumn get localPath => text()();
  TextColumn get contentType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get capturedAt => text().nullable()();
  /// QUEUED | UPLOADING | UPLOADED | FAILED — drives the UI badge.
  TextColumn get state => text().withDefault(const Constant('QUEUED'))();
  /// Server-side media id once uploaded.
  TextColumn get serverMediaId => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientRefId};
}

/// Phase 3 — last known GPS fix per device. Survives app kill so the
/// wizard + map have an immediate coordinate on cold start (the OS
/// doesn't deliver the first fix for ~10s after a cold boot).
@DataClassName('LocationRow')
class LocationRows extends Table {
  /// Single-row table keyed by a fixed id. Phase 3 only persists one
  /// device's last fix; multi-device is out of scope.
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get altitudeM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get headingDeg => real().nullable()();
  TextColumn get timestamp => text()();
  TextColumn get source => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Phase 4 — offline map raster tile cache.
///
/// Stores raw tile bytes (PNG / JPEG) keyed by the tile coordinate. Survives
/// the app process being killed so the NER operational region stays
/// available without network. The cache is filled lazily by user pan/zoom
/// (the OSM Tile Usage Policy permits per-user local caching; bulk
/// download is NOT performed).
///
/// Key shape: composite primary key on `(z, x, y, template_hash)`. The
/// template hash keeps tiles for different providers (OSM vs Mapbox vs a
/// future Bhuvan layer) from colliding when the cache is shared.
@DataClassName('MapTileRow')
class MapTileRows extends Table {
  IntColumn get z => integer()();
  IntColumn get x => integer()();
  IntColumn get y => integer()();
  /// sha256 of the URL template, so two providers never collide.
  TextColumn get templateHash => text()();
  BlobColumn get bytes => blob()();
  /// Captured MIME type ("image/png" / "image/jpeg") for header validation.
  TextColumn get contentType => text()();
  IntColumn get sizeBytes => integer()();
  /// SHA-256 of [bytes] for corruption detection (Phase 4 §4.3).
  TextColumn get sha256 => text()();
  /// Wall-clock instant this tile was first written. Drives LRU eviction.
  TextColumn get cachedAt => text()();
  /// Wall-clock instant this tile was last used. Updated on every read.
  TextColumn get lastAccessedAt => text()();
  /// Schema version of the cache row (allows future migrations without
  /// dropping the table).
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {z, x, y, templateHash};
}

/// Phase 5 — persisted offline road-graph snapshot (one row per segment).
///
/// Mirrors `GET /routing/graph-snapshot` (backend/app/routing/service.py
/// `graph_snapshot`), which reuses the authoritative /routing/plan edge
/// loader — the offline engine therefore plans over the SAME weights the
/// online engine uses. Survives app kill so a field officer can plan
/// without network (master prompt §5.1-5.3).
@DataClassName('OfflineGraphSegmentRow')
class OfflineGraphSegmentRows extends Table {
  TextColumn get segmentId => text()();
  TextColumn get roadCode => text()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  RealColumn get x1 => real()();
  RealColumn get y1 => real()();
  RealColumn get x2 => real()();
  RealColumn get y2 => real()();
  RealColumn get lengthKm => real()();
  /// Accessibility goodness 0-100 (latest score or server-derived fallback).
  RealColumn get accessibility => real()();
  /// Disruption risk 0-100 (latest prediction or server-derived fallback).
  RealColumn get riskPct => real()();
  /// OPEN | CLOSED — CLOSED rows are informational only (never routable).
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {segmentId};
}

/// Phase 5 — singleton metadata for the offline graph snapshot.
@DataClassName('OfflineGraphMetaRow')
class OfflineGraphMetaRows extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  TextColumn get fetchedAt => text()();
  IntColumn get segmentCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Phase 6 — persisted offline risk snapshot (one row per segment).
///
/// Mirrors `GET /risk/latest` (backend/app/risk/service.py). Survives app
/// kill so the last server-fused prediction for every exposed segment stays
/// available offline and is ALWAYS presented with its original `computed_at`
/// plus the local `fetched_at` (feature freshness). Never re-computed
/// on-device: the server risk engine remains the only source of scores.
@DataClassName('RiskSnapshotRow')
class RiskSnapshotRows extends Table {
  TextColumn get segmentId => text()();
  TextColumn get districtCode => text().nullable()();
  TextColumn get roadCode => text().nullable()();
  RealColumn get riskCurrent => real().nullable()();
  RealColumn get risk6h => real().nullable()();
  RealColumn get risk12h => real().nullable()();
  RealColumn get risk24h => real().nullable()();
  RealColumn get risk72h => real().nullable()();
  TextColumn get overallLabel => text().nullable()();
  TextColumn get severity => text().nullable()();
  TextColumn get topFactorsJson => text().nullable()();
  TextColumn get summarySentence => text().nullable()();
  RealColumn get baseValue => real().nullable()();
  TextColumn get mode => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get modelVersion => text().nullable()();
  /// Server-side model run instant (ISO-8601) — the feature snapshot age.
  TextColumn get computedAt => text().nullable()();
  /// Local fetch instant (ISO-8601) — when it was last synchronised.
  TextColumn get fetchedAt => text()();

  @override
  Set<Column> get primaryKey => {segmentId};
}

/// Phase 6 — singleton metadata for the offline risk snapshot.
@DataClassName('RiskSnapshotMetaRow')
class RiskSnapshotMetaRows extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  TextColumn get fetchedAt => text()();
  IntColumn get rowCount => integer().withDefault(const Constant(0))();
  TextColumn get districtCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SyncQueueRows,
    SyncAttemptRows,
    DraftRows,
    DraftMediaRows,
    LocationRows,
    MapTileRows,
    OfflineGraphSegmentRows,
    OfflineGraphMetaRows,
    RiskSnapshotRows,
    RiskSnapshotMetaRows,
  ],
)
class SyncQueueDatabase extends _$SyncQueueDatabase {
  SyncQueueDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Additive migrations only — existing rows from earlier schema
          // versions stay intact.
          if (from < 4) {
            await m.createTable(mapTileRows);
            await customStatement(
                'create index if not exists idx_map_tile_lru '
                'on map_tile_rows (template_hash, last_accessed_at)');
            await customStatement(
                'create index if not exists idx_map_tile_size '
                'on map_tile_rows (template_hash, size_bytes)');
          }
          if (from < 5) {
            await m.createTable(offlineGraphSegmentRows);
            await m.createTable(offlineGraphMetaRows);
          }
          if (from < 6) {
            await m.createTable(riskSnapshotRows);
            await m.createTable(riskSnapshotMetaRows);
          }
        },
      );

  /// Creates an in-memory database for tests.
  ///
  /// On native, uses [NativeDatabase.memory]. On web, uses a [WebDatabase]
  /// which stores data in the browser's localStorage.
  static SyncQueueDatabase memory() {
    return SyncQueueDatabase(createInMemoryExecutor());
  }

  /// Opens (or creates) the platform-appropriate database.
  ///
  /// On native platforms (Android, iOS, Windows, macOS, Linux), this opens
  /// an on-disk SQLite database file in the application documents directory.
  ///
  /// On web, this creates a browser-based database using sql.js (data is
  /// stored in IndexedDB or localStorage and persists across page reloads).
  static Future<SyncQueueDatabase> openInApplicationDocuments() async {
    final executor = await createDatabaseExecutor();
    return SyncQueueDatabase(executor);
  }
}