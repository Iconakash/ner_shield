// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessibilitySegment _$AccessibilitySegmentFromJson(
  Map<String, dynamic> json,
) => _AccessibilitySegment(
  segmentId: json['segment_id'] as String,
  accClassification: json['acc_classification'] as String?,
  accScore: (json['acc_score'] as num?)?.toDouble(),
  factors: (json['factors'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$AccessibilitySegmentToJson(
  _AccessibilitySegment instance,
) => <String, dynamic>{
  'segment_id': instance.segmentId,
  'acc_classification': instance.accClassification,
  'acc_score': instance.accScore,
  'factors': instance.factors,
  'updated_at': instance.updatedAt,
};
