import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_health.freezed.dart';
part 'data_health.g.dart';

/// `GET /data-health` (reference `backend/app/data_health/router.py`).
@freezed
sealed class DataHealth with _$DataHealth {
  const factory DataHealth({
    required String title,
    List<DataSource>? sources,
    DataHealthSummary? summary,
  }) = _DataHealth;

  factory DataHealth.fromJson(Map<String, dynamic> json) =>
      _$DataHealthFromJson(json);
}

/// Freshness of one data source. `freshness`:
/// `LIVE | RECENT | STALE | UNAVAILABLE`. Sources pending authorization are
/// never shown as live.
@freezed
sealed class DataSource with _$DataSource {
  const factory DataSource({
    String? code,
    String? name,
    bool? enabled,
    String? status,
    String? freshness,
    double? confidence,
    String? licenseNote,
    String? lastSuccessAt,
  }) = _DataSource;

  factory DataSource.fromJson(Map<String, dynamic> json) =>
      _$DataSourceFromJson(json);
}

/// Rollup counts over the source list.
@freezed
sealed class DataHealthSummary with _$DataHealthSummary {
  const factory DataHealthSummary({
    int? total,
    int? live,
    int? recent,
    int? stale,
    int? unavailable,
  }) = _DataHealthSummary;

  factory DataHealthSummary.fromJson(Map<String, dynamic> json) =>
      _$DataHealthSummaryFromJson(json);
}