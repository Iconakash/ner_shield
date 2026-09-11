// Phase 3 — concrete [LocationService] backed by the `geolocator`
// package. Android-first per the master prompt (iOS is documented as
// deferred). Privacy-respecting: never starts a stream before the user
// grants permission, and never requests background location.

import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;

import 'location_models.dart';
import 'location_service.dart';
import 'location_settings.dart';

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({this.settings = LocationSettings.defaults});

  final LocationSettings settings;

  LocationFix? _last;
  StreamController<LocationFix>? _ctrl;
  StreamSubscription<geo.Position>? _sub;

  @override
  LocationFix? get lastKnown => _last;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceOn = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return LocationPermissionStatus.serviceDisabled;
    var perm = await geo.Geolocator.checkPermission();
    if (perm == geo.LocationPermission.denied) {
      perm = await geo.Geolocator.requestPermission();
    }
    return _mapPermission(perm);
  }

  @override
  Future<bool> isServiceEnabled() =>
      geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationFix?> getCurrentPosition({Duration? timeout}) async {
    final perm = await geo.Geolocator.checkPermission();
    if (perm == geo.LocationPermission.denied ||
        perm == geo.LocationPermission.deniedForever) {
      return null;
    }
    if (!await geo.Geolocator.isLocationServiceEnabled()) return null;
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: settings.distanceFilterM.toInt(),
          timeLimit: timeout ?? const Duration(seconds: 10),
        ),
      );
      final fix = _toFix(pos);
      _last = fix;
      return fix;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LocationFix> getPositionStream() {
    if (_ctrl != null) return _ctrl!.stream;
    _ctrl = StreamController<LocationFix>.broadcast(
      onCancel: () => _stopStream(),
    );
    _startStream();
    return _ctrl!.stream;
  }

  @override
  Future<void> dispose() async {
    await _stopStream();
    await _ctrl?.close();
    _ctrl = null;
  }

  // -- internals -----------------------------------------------------------

  Future<void> _startStream() async {
    final perm = await geo.Geolocator.checkPermission();
    if (perm == geo.LocationPermission.denied ||
        perm == geo.LocationPermission.deniedForever) {
      _ctrl?.close();
      _ctrl = null;
      return;
    }
    _sub = geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: settings.distanceFilterM.toInt(),
      ),
    ).listen((pos) {
      final fix = _toFix(pos);
      if (fix.accuracyM != null &&
          fix.accuracyM! > settings.accuracyMinM) {
        return;
      }
      final prev = _last;
      if (prev?.accuracyM != null &&
          fix.accuracyM != null &&
          (prev!.accuracyM! - fix.accuracyM!) < -settings.maxAccuracyDropM) {
        return;
      }
      _last = fix;
      _ctrl?.add(fix);
    }, onError: (Object e) {
      // Do not propagate — geolocator fires transient errors on location
      // toggle-off. The next valid fix resumes naturally.
    });
  }

  Future<void> _stopStream() async {
    await _sub?.cancel();
    _sub = null;
  }

  LocationFix _toFix(geo.Position p) {
    return LocationFix(
      lat: p.latitude,
      lon: p.longitude,
      timestamp: p.timestamp,
      accuracyM: p.accuracy,
      altitudeM: p.altitude,
      speedMps: p.speed,
      headingDeg: p.heading,
      source: LocationSource.gps,
    );
  }

  LocationPermissionStatus _mapPermission(geo.LocationPermission p) {
    switch (p) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case geo.LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case geo.LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case geo.LocationPermission.unableToDetermine:
        return LocationPermissionStatus.notDetermined;
    }
  }
}