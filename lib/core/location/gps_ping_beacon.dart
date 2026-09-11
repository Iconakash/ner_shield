// Phase 3 — listens to [LocationService.getPositionStream] and emits
// [SyncQueueEntry] ops of opType `GPS_PING` into the persistent queue.
//
// Behaviour:
//   * Honours [LocationSettings.accuracyMinM] — drops fixes worse than
//     the configured threshold.
//   * Coalesces by [LocationSettings.beaconIntervalSeconds].
//   * Persists every emitted fix via [LastKnownLocationStore] so the
//     wizard + map see the latest location on next launch.
//   * Each GPS_PING has a unique [SyncQueueEntry.clientOpId] (uuid v4).
//     Server-side idempotency is already in place per
//     `backend/app/sync/service.py`.

import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../models/sync_queue_entry.dart';
import '../sync/sync_queue.dart';
import 'last_known_location_store.dart';
import 'location_models.dart';
import 'location_service.dart';
import 'location_settings.dart';

class GpsPingBeacon {
  GpsPingBeacon({
    required this._location,
    required this._queue,
    required this._store,
    this._settings = LocationSettings.defaults,
    this._shipmentId,
  });

  static const _uuid = Uuid();

  final LocationService _location;
  final SyncQueue _queue;
  final LastKnownLocationStore _store;
  final LocationSettings _settings;
  final String? _shipmentId;

  StreamSubscription<LocationFix>? _sub;
  DateTime? _lastEmit;

  /// True when the user has granted permission AND the OS-level GPS
  /// service is enabled.
  bool get active => _sub != null;

  Future<void> start() async {
    if (_sub != null) return;
    final status = await _location.requestPermission();
    if (status != LocationPermissionStatus.granted) return;
    if (!await _location.isServiceEnabled()) return;
    _sub = _location.getPositionStream().listen(_onFix);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onFix(LocationFix fix) async {
    if (fix.accuracyM != null && fix.accuracyM! > _settings.accuracyMinM) {
      return;
    }
    final now = DateTime.now().toUtc();
    if (_lastEmit != null &&
        now.difference(_lastEmit!).inSeconds <
            _settings.beaconIntervalSeconds) {
      return;
    }
    _lastEmit = now;
    await _store.save(fix);
    final observed = fix.timestamp.toUtc().toIso8601String();
    final payload = fix.toPayload(observedAtIso: observed);
    final entry = SyncQueueEntry(
      clientOpId: _uuid.v4(),
      opType: 'GPS_PING',
      entityType: 'GPS',
      status: SyncQueueStatus.pending,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      payload: {
        ...payload,
        if (_shipmentId != null) 'shipment_id': _shipmentId,
      },
    );
    await _queue.enqueue(entry);
  }
}