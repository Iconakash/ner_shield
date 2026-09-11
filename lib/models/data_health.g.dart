// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DataHealth _$DataHealthFromJson(Map<String, dynamic> json) => _DataHealth(
  title: json['title'] as String,
  sources: (json['sources'] as List<dynamic>?)
      ?.map((e) => DataSource.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: json['summary'] == null
      ? null
      : DataHealthSummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DataHealthToJson(_DataHealth instance) =>
    <String, dynamic>{
      'title': instance.title,
      'sources': instance.sources,
      'summary': instance.summary,
    };

_DataSource _$DataSourceFromJson(Map<String, dynamic> json) => _DataSource(
  code: json['code'] as String?,
  name: json['name'] as String?,
  enabled: json['enabled'] as bool?,
  status: json['status'] as String?,
  freshness: json['freshness'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble(),
  licenseNote: json['license_note'] as String?,
  lastSuccessAt: json['last_success_at'] as String?,
);

Map<String, dynamic> _$DataSourceToJson(_DataSource instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'enabled': instance.enabled,
      'status': instance.status,
      'freshness': instance.freshness,
      'confidence': instance.confidence,
      'license_note': instance.licenseNote,
      'last_success_at': instance.lastSuccessAt,
    };

_DataHealthSummary _$DataHealthSummaryFromJson(Map<String, dynamic> json) =>
    _DataHealthSummary(
      total: (json['total'] as num?)?.toInt(),
      live: (json['live'] as num?)?.toInt(),
      recent: (json['recent'] as num?)?.toInt(),
      stale: (json['stale'] as num?)?.toInt(),
      unavailable: (json['unavailable'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DataHealthSummaryToJson(_DataHealthSummary instance) =>
    <String, dynamic>{
      'total': instance.total,
      'live': instance.live,
      'recent': instance.recent,
      'stale': instance.stale,
      'unavailable': instance.unavailable,
    };
