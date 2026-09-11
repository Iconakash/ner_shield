// Phase 3 — abstraction over the platform's location subsystem.
//
// The contract is intentionally small + Dart-only so test code can swap
// in a [MockLocationService] without touching the geolocator package.
// Production wires [GeolocatorLocationService] at app boot.

import 'location_models.dart';
import 'location_settings.dart';

/// Read-only + watch-only view of the platform's location subsystem.
///
/// Implementations must:
///   * never collect data when [requestPermission] has not been granted,
///   * respect [LocationSettings.beaconIntervalSeconds],
///   * report failures via the explicit [LocationPermissionStatus]
///     vocabulary — never via a swallowed exception.
abstract class LocationService {
  /// Probes the platform for permission + GPS-service status. Returns
  /// the merged result so the UI can show one precise message.
  Future<LocationPermissionStatus> requestPermission();

  /// Single-shot current fix. Returns `null` when the device can't
  /// produce one (denied permission / GPS toggle off / timed out).
  /// Does NOT throw — caller decides whether null is fatal.
  Future<LocationFix?> getCurrentPosition({Duration? timeout});

  /// Stream of fixes from this point on. Cancelling the subscription
  /// (or calling [dispose]) must stop the underlying platform stream.
  Stream<LocationFix> getPositionStream();

  /// Latest successful fix observed by this service. Held in memory;
  /// see [LastKnownLocationStore] for the persisted equivalent.
  LocationFix? get lastKnown;

  /// True iff the platform's location service is enabled (GPS toggle).
  Future<bool> isServiceEnabled();

  /// Release the platform stream + listeners.
  Future<void> dispose();
}