import 'package:intl/intl.dart';

/// Small, safe date helpers for stale-data / freshness labels.
abstract final class TimeFormat {
  static final DateFormat _clock = DateFormat('HH:mm:ss');
  static final DateFormat _full = DateFormat('d MMM yyyy · HH:mm');

  /// ISO-8601 API timestamp → local clock time, or [fallback].
  static String clock(String? iso, {String fallback = '—'}) {
    final dt = _local(iso);
    if (dt == null) return fallback;
    return _clock.format(dt);
  }

  /// ISO-8601 API timestamp → local "date · time", or [fallback].
  static String full(String? iso, {String fallback = '—'}) {
    final dt = _local(iso);
    if (dt == null) return fallback;
    return _full.format(dt);
  }

  static DateTime? _local(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }
}