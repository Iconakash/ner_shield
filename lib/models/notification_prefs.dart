/// Client-safe notification preferences (`/notifications/preferences`).
///
/// Backend shape (docs/api-contract-map.md): GET returns prefs; PUT accepts
/// `{channels: {}, min_severity}`. Parsed defensively — a malformed channels
/// map degrades to an empty map instead of failing the whole screen.
/// Hand-rolled (no codegen): two fields, no backend row complexity.
class NotificationPreferences {
  const NotificationPreferences({
    this.channels = const {},
    this.minSeverity,
  });

  /// Channel id (e.g. `EMAIL`, `SMS`) → enabled.
  final Map<String, bool> channels;
  final String? minSeverity;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['channels'];
    final channels = <String, bool>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String) channels[key] = value == true;
      });
    }
    final min = json['min_severity'];
    return NotificationPreferences(
      channels: channels,
      minSeverity: min is String ? min : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'channels': channels,
        if (minSeverity != null) 'min_severity': minSeverity,
      };

  NotificationPreferences copyWith({
    Map<String, bool>? channels,
    String? minSeverity,
    bool clearMinSeverity = false,
  }) {
    return NotificationPreferences(
      channels: channels ?? this.channels,
      minSeverity: clearMinSeverity ? null : (minSeverity ?? this.minSeverity),
    );
  }

  /// Channels the user has opted into.
  List<String> get enabledChannels =>
      channels.entries.where((e) => e.value).map((e) => e.key).toList();
}