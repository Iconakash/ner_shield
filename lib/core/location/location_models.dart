// Location types for Phase 3.
//
// Kept in a separate file from the abstraction so tests + screens can
// import the data types without pulling in the geolocator package.

/// One GPS fix observed by the device.
///
/// All fields beyond [lat]/[lon] are best-effort and may be `null` when
/// the OS reports a fix that doesn't include them. We persist this whole
/// record to the last-known store so the wizard + map have an immediate
/// coordinate on app start.
class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lon,
    required this.timestamp,
    this.accuracyM,
    this.altitudeM,
    this.speedMps,
    this.headingDeg,
    this.source = LocationSource.gps,
  });

  /// Latitude in degrees, WGS-84.
  final double lat;

  /// Longitude in degrees, WGS-84.
  final double lon;

  /// Wall-clock instant the OS reported for this fix.
  final DateTime timestamp;

  /// Reported horizontal accuracy in meters (null = unknown).
  final double? accuracyM;

  /// Altitude above the WGS-84 ellipsoid in meters (null = unknown).
  final double? altitudeM;

  /// Ground speed in meters per second (null = unknown).
  final double? speedMps;

  /// Heading / bearing in degrees, 0 = north, clockwise (null = unknown).
  final double? headingDeg;

  /// Where this fix came from — used by the UI to label cached vs live.
  final LocationSource source;

  /// True when this fix's reported accuracy is good enough for navigation
  /// or report submission. The threshold defaults to 50m but the
  /// `LocationSettings` may tighten it for high-priority work.
  bool isAccurateEnough({double accuracyMin = 50}) {
    final a = accuracyM;
    if (a == null) return false;
    return a <= accuracyMin;
  }

  /// Serialises to the shape that the `GPS_PING` op carries in
  /// `/sync/push`. Field names match `backend/app/gps/schemas.py`.
  Map<String, dynamic> toPayload({required String observedAtIso}) {
    return {
      'latitude': lat,
      'longitude': lon,
      'observed_at': observedAtIso,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (headingDeg != null) 'heading_deg': headingDeg,
    };
  }

  /// Convenience for "what the wizard sends to the server".
  double get latitude => lat;
  double get longitude => lon;

  /// Inverse of [toPayload].
  factory LocationFix.fromJson(Map<String, dynamic> j) {
    return LocationFix(
      lat: (j['latitude'] as num).toDouble(),
      lon: (j['longitude'] as num).toDouble(),
      timestamp: DateTime.tryParse(
            (j['observed_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      accuracyM: (j['accuracy_m'] as num?)?.toDouble(),
      altitudeM: (j['altitude_m'] as num?)?.toDouble(),
      speedMps: (j['speed_mps'] as num?)?.toDouble(),
      headingDeg: (j['heading_deg'] as num?)?.toDouble(),
    );
  }
}

enum LocationSource { gps, fused, network, cached }

/// Tri-state permission result surfaced by the abstraction. Mirrors the
/// Android / iOS distinctions the geolocator plugin exposes.
enum LocationPermissionStatus {
  /// User granted permission.
  granted,
  /// User denied permission once.
  denied,
  /// User selected "never ask again" / iOS restricted — must send to settings.
  deniedForever,
  /// The user toggled the OS-level location service off. Distinct from
  /// denied permission; user must flip the GPS toggle.
  serviceDisabled,
  /// Permission not yet requested this session.
  notDetermined,
}