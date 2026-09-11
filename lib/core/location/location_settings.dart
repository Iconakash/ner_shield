// Phase 3 — runtime knobs for the GPS beacon.
//
// Kept small and immutable so a single instance can be passed through
// the provider tree without rebuilding every emission.

class LocationSettings {
  const LocationSettings({
    this.accuracyMinM = 50,
    this.distanceFilterM = 10,
    this.beaconIntervalSeconds = 30,
    this.maxAccuracyDropM = 500,
  });

  /// Discard fixes worse than this many meters of reported horizontal
  /// accuracy. The OS still tracks position internally; we just refuse to
  /// enqueue / forward low-quality fixes.
  final double accuracyMinM;

  /// Minimum movement before the OS emits a new position. Smaller values
  /// = more pings; larger values = lower battery cost.
  final double distanceFilterM;

  /// Minimum interval between consecutive GPS_PING ops (seconds). Mirrors
  /// the server-side `gps_beacon_s` from `/sync/policy`.
  final int beaconIntervalSeconds;

  /// Discard a fix if its accuracy is worse than the last good fix by
  /// more than this many meters. Guards against sudden GPS-lock drops
  /// from generating a burst of low-quality pings.
  final double maxAccuracyDropM;

  static const LocationSettings defaults = LocationSettings();
}