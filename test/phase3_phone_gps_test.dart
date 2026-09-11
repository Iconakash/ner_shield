// Phase 3 - Phone GPS test matrix (master prompt sec 3.5). Runs against
// the in-memory Drift backend; the platform channel is faked via
// [MockLocationService].

import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/location/gps_ping_beacon.dart';
import 'package:ner_shield/core/location/last_known_location_store.dart';
import 'package:ner_shield/core/location/location_models.dart';
import 'package:ner_shield/core/location/location_settings.dart';
import 'package:ner_shield/core/location/mock_location_service.dart';
import 'package:ner_shield/core/sync/persistent_sync_queue_storage.dart';
import 'package:ner_shield/core/sync/sync_queue.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';

LocationFix _fix({
  double lat = 26.1,
  double lon = 91.7,
  double accuracyM = 25,
  double? altitudeM,
  double? speedMps,
  double? headingDeg,
  DateTime? at,
}) =>
    LocationFix(
      lat: lat,
      lon: lon,
      accuracyM: accuracyM,
      altitudeM: altitudeM,
      speedMps: speedMps,
      headingDeg: headingDeg,
      timestamp: at ?? DateTime.now().toUtc(),
    );

void main() {
  group('Phase 3 - LocationFix payload', () {
    test('toPayload carries the fields the backend expects', () {
      final iso = '2026-09-05T10:00:00.000Z';
      final p = _fix(accuracyM: 12, altitudeM: 200, speedMps: 1.5, headingDeg: 90)
          .toPayload(observedAtIso: iso);
      expect(p['latitude'], 26.1);
      expect(p['longitude'], 91.7);
      expect(p['observed_at'], iso);
      expect(p['accuracy_m'], 12);
      expect(p['altitude_m'], 200);
      expect(p['speed_mps'], 1.5);
      expect(p['heading_deg'], 90);
    });

    test('isAccurateEnough honours the configured threshold', () {
      final good = _fix(accuracyM: 30);
      final bad = _fix(accuracyM: 200);
      expect(good.isAccurateEnough(accuracyMin: 50), isTrue);
      expect(bad.isAccurateEnough(accuracyMin: 50), isFalse);
    });
  });

  group('Phase 3 - LastKnownLocationStore', () {
    late SyncQueueDatabase db;
    late LastKnownLocationStore store;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      store = LastKnownLocationStore(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('save then load round-trips the fix', () async {
      final fix = _fix(accuracyM: 12, altitudeM: 100);
      await store.save(fix);
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.lat, fix.lat);
      expect(loaded.lon, fix.lon);
      expect(loaded.accuracyM, fix.accuracyM);
      expect(loaded.source, LocationSource.gps);
    });

    test('clear wipes the row', () async {
      await store.save(_fix());
      await store.clear();
      expect(await store.load(), isNull);
    });
  });

  group('Phase 3 - GpsPingBeacon', () {
    late SyncQueueDatabase db;
    late SyncQueue queue;
    late MockLocationService loc;
    late LastKnownLocationStore store;
    late GpsPingBeacon beacon;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      queue = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await queue.ensureLoaded();
      loc = MockLocationService();
      store = LastKnownLocationStore(db);
      beacon = GpsPingBeacon(
        location: loc,
        queue: queue,
        store: store,
        settings: const LocationSettings(
          accuracyMinM: 50,
          beaconIntervalSeconds: 0,
          distanceFilterM: 10,
        ),
      );
    });

    tearDown(() async {
      await beacon.stop();
      await loc.dispose();
      await queue.dispose();
      await db.close();
    });

    test('start is a no-op when permission is denied', () async {
      loc.permission = LocationPermissionStatus.denied;
      await beacon.start();
      expect(beacon.active, isFalse);
      expect(queue.entries, isEmpty);
    });

    test('start is a no-op when the OS GPS toggle is off', () async {
      loc.permission = LocationPermissionStatus.granted;
      loc.serviceEnabled = false;
      await beacon.start();
      expect(beacon.active, isFalse);
      expect(queue.entries, isEmpty);
    });

    test('emitted fix becomes a GPS_PING queue op with the expected payload',
        () async {
      await beacon.start();
      expect(beacon.active, isTrue);
      loc.emit(_fix(accuracyM: 10));
      await Future<void>.delayed(Duration.zero);
      final ops = queue.entries;
      expect(ops, hasLength(1));
      expect(ops.single.opType, 'GPS_PING');
      expect(ops.single.entityType, 'GPS');
      expect(ops.single.payload['latitude'], 26.1);
      expect(ops.single.payload['longitude'], 91.7);
      expect(ops.single.payload['accuracy_m'], 10);
    });

    test('poor-accuracy fix is dropped before queueing', () async {
      await beacon.start();
      loc.emit(_fix(accuracyM: 500)); // > accuracyMinM (50)
      await Future<void>.delayed(Duration.zero);
      expect(queue.entries, isEmpty);
    });

    test('restart recovery: last fix survives via the store', () async {
      await beacon.start();
      loc.emit(_fix(accuracyM: 15));
      await Future<void>.delayed(Duration.zero);
      // Tear down everything except the DB.
      await beacon.stop();
      await loc.dispose();
      await queue.dispose();
      // New store over the same DB; last fix still here.
      final store2 = LastKnownLocationStore(db);
      final loaded = await store2.load();
      expect(loaded, isNotNull);
      expect(loaded!.accuracyM, 15);
      await db.close();
    });
  });
}