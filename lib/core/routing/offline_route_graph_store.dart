// Phase 5 — persists the offline routing snapshot (§5.1) in the shared
// Drift database so the offline engine survives app kill. The snapshot
// comes from `GET /routing/graph-snapshot`, which reuses the server's
// authoritative edge loader.

import 'package:drift/drift.dart';

import '../../models/route_graph_snapshot.dart';
import '../sync/sync_queue_database.dart';
import 'offline_route_engine.dart';

/// A loaded snapshot: open rows for graph building + provenance.
class StoredGraphSnapshot {
  const StoredGraphSnapshot({
    required this.openRows,
    required this.closedSegmentIds,
    required this.fetchedAt,
  });

  final List<RawGraphEdge> openRows;
  final List<String> closedSegmentIds;
  final DateTime fetchedAt;

  bool isStale({Duration staleAfter = defaultStaleAfter}) =>
      DateTime.now().toUtc().difference(fetchedAt) > staleAfter;

  Duration get age => DateTime.now().toUtc().difference(fetchedAt);
}

/// Default freshness budget for offline plans (§5.3: stale must be labelled).
const Duration defaultStaleAfter = Duration(hours: 6);

class OfflineRouteGraphStore {
  OfflineRouteGraphStore(this._db);

  final SyncQueueDatabase _db;

  /// Replaces the whole snapshot atomically (server truth wins).
  Future<void> save(RouteGraphSnapshot snapshot) async {
    await _db.transaction(() async {
      await _db.delete(_db.offlineGraphSegmentRows).go();
      for (final s in snapshot.openSegments) {
        await _db.into(_db.offlineGraphSegmentRows).insert(
              OfflineGraphSegmentRowsCompanion.insert(
                segmentId: s.segmentId,
                roadCode: s.roadCode,
                seq: Value(s.seq),
                x1: s.x1,
                y1: s.y1,
                x2: s.x2,
                y2: s.y2,
                lengthKm: s.lengthKm,
                accessibility: s.accessibility,
                riskPct: s.riskPct,
                status: 'OPEN',
              ),
            );
      }
      for (final s in snapshot.closedSegments) {
        await _db.into(_db.offlineGraphSegmentRows).insert(
              OfflineGraphSegmentRowsCompanion.insert(
                segmentId: s.segmentId,
                roadCode: s.roadCode,
                seq: Value(s.seq),
                x1: s.x1,
                y1: s.y1,
                x2: s.x2,
                y2: s.y2,
                lengthKm: 0,
                accessibility: 0,
                riskPct: 100,
                status: 'CLOSED',
              ),
            );
      }
      await _db
          .into(_db.offlineGraphMetaRows)
          .insertOnConflictUpdate(
            OfflineGraphMetaRowsCompanion.insert(
              id: const Value('singleton'),
              fetchedAt: snapshot.fetchedAt.toIso8601String(),
              segmentCount: Value(snapshot.openSegments.length),
            ),
          );
    });
  }

  /// Loads the persisted snapshot. Null when never fetched.
  Future<StoredGraphSnapshot?> load() async {
    final meta = await (_db.select(_db.offlineGraphMetaRows)
          ..where((t) => t.id.equals('singleton')))
        .getSingleOrNull();
    if (meta == null) return null;
    final rows = await (_db.select(_db.offlineGraphSegmentRows)).get();
    final openRows = <RawGraphEdge>[];
    final closed = <String>[];
    for (final r in rows) {
      if (r.status == 'CLOSED') {
        closed.add(r.segmentId);
        continue;
      }
      openRows.add(RawGraphEdge(
        segmentId: r.segmentId,
        roadCode: r.roadCode,
        seq: r.seq,
        x1: r.x1,
        y1: r.y1,
        x2: r.x2,
        y2: r.y2,
        lengthKm: r.lengthKm,
        accessibility: r.accessibility,
        riskPct: r.riskPct,
      ));
    }
    return StoredGraphSnapshot(
      openRows: openRows,
      closedSegmentIds: closed,
      fetchedAt: DateTime.tryParse(meta.fetchedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// When the snapshot was last refreshed (null = never).
  Future<DateTime?> lastFetchedAt() async {
    final meta = await (_db.select(_db.offlineGraphMetaRows)
          ..where((t) => t.id.equals('singleton')))
        .getSingleOrNull();
    if (meta == null) return null;
    return DateTime.tryParse(meta.fetchedAt);
  }
}