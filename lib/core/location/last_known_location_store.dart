// Phase 3 — persistent last-known-location cache (single row keyed
// `singleton`). Survives app kill so the wizard + map have an
// immediate coordinate on cold start.

import 'package:drift/drift.dart';

import '../sync/sync_queue_database.dart';
import 'location_models.dart';

class LastKnownLocationStore {
  LastKnownLocationStore(this._db);

  final SyncQueueDatabase _db;

  Future<void> save(LocationFix fix) async {
    await _db.into(_db.locationRows).insertOnConflictUpdate(
      LocationRowsCompanion.insert(
        id: const Value('singleton'),
        lat: fix.lat,
        lon: fix.lon,
        accuracyM: Value(fix.accuracyM),
        altitudeM: Value(fix.altitudeM),
        speedMps: Value(fix.speedMps),
        headingDeg: Value(fix.headingDeg),
        timestamp: fix.timestamp.toUtc().toIso8601String(),
        source: Value(fix.source.name),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Future<LocationFix?> load() async {
    final row = await (_db.select(_db.locationRows)
          ..where((t) => t.id.equals('singleton')))
        .getSingleOrNull();
    if (row == null) return null;
    return LocationFix(
      lat: row.lat,
      lon: row.lon,
      timestamp: DateTime.tryParse(row.timestamp) ?? DateTime.now().toUtc(),
      accuracyM: row.accuracyM,
      altitudeM: row.altitudeM,
      speedMps: row.speedMps,
      headingDeg: row.headingDeg,
      source: _parseSource(row.source),
    );
  }

  Future<void> clear() async {
    await (_db.delete(_db.locationRows)
          ..where((t) => t.id.equals('singleton')))
        .go();
  }

  LocationSource _parseSource(String? raw) {
    for (final s in LocationSource.values) {
      if (s.name == raw) return s;
    }
    return LocationSource.cached;
  }
}