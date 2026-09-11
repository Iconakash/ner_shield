// Phase 3 — in-memory [LocationService] for tests + non-Android targets.
//
// Used by:
//   * the widget/unit test suites (no plugin platform channel),
//   * the production provider graph on non-Android platforms where the
//     geolocator plugin can't run (documented as deferred per the
//     master prompt).

import 'dart:async';

import 'location_models.dart';
import 'location_service.dart';
import 'location_settings.dart';

class MockLocationService implements LocationService {
  MockLocationService({
    this.permission = LocationPermissionStatus.granted,
    this.serviceEnabled = true,
    this.settings = LocationSettings.defaults,
  });

  /// Current permission state. Mutable so tests can flip it.
  LocationPermissionStatus permission;

  /// GPS-toggle state. Mutable so tests can flip it.
  bool serviceEnabled;

  final LocationSettings settings;

  final StreamController<LocationFix> _ctrl =
      StreamController<LocationFix>.broadcast();
  LocationFix? _last;

  /// Emit a synthetic location to all listeners + persist as lastKnown.
  void emit(LocationFix fix) {
    _last = fix;
    _ctrl.add(fix);
  }

  @override
  LocationFix? get lastKnown => _last;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationFix?> getCurrentPosition({Duration? timeout}) async {
    if (permission != LocationPermissionStatus.granted) return null;
    if (!serviceEnabled) return null;
    return _last;
  }

  @override
  Stream<LocationFix> getPositionStream() => _ctrl.stream;

  @override
  Future<void> dispose() async {
    await _ctrl.close();
  }
}