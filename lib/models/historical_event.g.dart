// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historical_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoricalEvent _$HistoricalEventFromJson(Map<String, dynamic> json) =>
    _HistoricalEvent(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      eventType: json['event_type'] as String?,
      occurredAt: json['occurred_at'] as String?,
      districtCode: json['district_code'] as String?,
      stateCode: json['state_code'] as String?,
      dataQuality: json['data_quality'] as String?,
      datasetVersion: json['dataset_version'] as String?,
      observationCount: (json['observation_count'] as num?)?.toInt(),
      latestRun: json['latest_run'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$HistoricalEventToJson(_HistoricalEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'event_type': instance.eventType,
      'occurred_at': instance.occurredAt,
      'district_code': instance.districtCode,
      'state_code': instance.stateCode,
      'data_quality': instance.dataQuality,
      'dataset_version': instance.datasetVersion,
      'observation_count': instance.observationCount,
      'latest_run': instance.latestRun,
    };

_HistoricalValidationRun _$HistoricalValidationRunFromJson(
  Map<String, dynamic> json,
) => _HistoricalValidationRun(
  id: json['id'] as String,
  eventId: json['event_id'] as String?,
  modelName: json['model_name'] as String?,
  modelVersion: json['model_version'] as String?,
  datasetVersion: json['dataset_version'] as String?,
  metrics: json['metrics'] as Map<String, dynamic>?,
  ranAt: json['ran_at'] as String?,
);

Map<String, dynamic> _$HistoricalValidationRunToJson(
  _HistoricalValidationRun instance,
) => <String, dynamic>{
  'id': instance.id,
  'event_id': instance.eventId,
  'model_name': instance.modelName,
  'model_version': instance.modelVersion,
  'dataset_version': instance.datasetVersion,
  'metrics': instance.metrics,
  'ran_at': instance.ranAt,
};
