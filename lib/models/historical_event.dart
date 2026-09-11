import 'package:freezed_annotation/freezed_annotation.dart';

part 'historical_event.freezed.dart';
part 'historical_event.g.dart';

/// `GET /historical/events` — one historical event row (P4 historical
/// validation, master prompt §Historical). All accuracy numbers carry a
/// `data_quality` tag (SAMPLE | SIMULATED | MEASURED | NO_DATASET) so the
/// UI can never present a synthetic score as a measured result.
@freezed
sealed class HistoricalEvent with _$HistoricalEvent {
  const factory HistoricalEvent({
    required String id,
    String? title,
    String? description,
    String? eventType,
    String? occurredAt,
    String? districtCode,
    String? stateCode,
    @JsonKey(name: 'data_quality') String? dataQuality,
    @JsonKey(name: 'dataset_version') String? datasetVersion,
    @JsonKey(name: 'observation_count') int? observationCount,
    @JsonKey(name: 'latest_run') Map<String, dynamic>? latestRun,
  }) = _HistoricalEvent;

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) =>
      _$HistoricalEventFromJson(json);

  const HistoricalEvent._();

  /// True when the dataset is MEASURED — only then may a metric be displayed
  /// without an explicit "SAMPLE" or "SIMULATED" badge (master prompt §42).
  bool get isMeasured => dataQuality == 'MEASURED';
}

/// One row of a historical validation run (metrics + per-observation
/// predictions). Used by the detail screen.
@freezed
sealed class HistoricalValidationRun with _$HistoricalValidationRun {
  const factory HistoricalValidationRun({
    required String id,
    @JsonKey(name: 'event_id') String? eventId,
    @JsonKey(name: 'model_name') String? modelName,
    @JsonKey(name: 'model_version') String? modelVersion,
    @JsonKey(name: 'dataset_version') String? datasetVersion,
    Map<String, dynamic>? metrics,
    @JsonKey(name: 'ran_at') String? ranAt,
  }) = _HistoricalValidationRun;

  factory HistoricalValidationRun.fromJson(Map<String, dynamic> json) =>
      _$HistoricalValidationRunFromJson(json);
}