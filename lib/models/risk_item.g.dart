// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RiskPrediction _$RiskPredictionFromJson(Map<String, dynamic> json) =>
    _RiskPrediction(
      segmentId: json['segment_id'] as String,
      roadCode: json['road_code'] as String?,
      districtCode: json['district_code'] as String?,
      districtName: json['district_name'] as String?,
      riskCurrent: (json['risk_current'] as num?)?.toDouble(),
      risk6h: (json['risk6h'] as num?)?.toDouble(),
      risk12h: (json['risk12h'] as num?)?.toDouble(),
      risk24h: (json['risk24h'] as num?)?.toDouble(),
      risk72h: (json['risk72h'] as num?)?.toDouble(),
      overallLabel: json['overall_label'] as String?,
      severity: json['severity'] as String?,
      topFactors: (json['top_factors'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      summarySentence: json['summary_sentence'] as String?,
      baseValue: (json['base_value'] as num?)?.toDouble(),
      mode: json['mode'] as String?,
      modelName: json['model_name'] as String?,
      modelVersion: json['model_version'] as String?,
      computedAt: json['computed_at'] as String?,
    );

Map<String, dynamic> _$RiskPredictionToJson(_RiskPrediction instance) =>
    <String, dynamic>{
      'segment_id': instance.segmentId,
      'road_code': instance.roadCode,
      'district_code': instance.districtCode,
      'district_name': instance.districtName,
      'risk_current': instance.riskCurrent,
      'risk6h': instance.risk6h,
      'risk12h': instance.risk12h,
      'risk24h': instance.risk24h,
      'risk72h': instance.risk72h,
      'overall_label': instance.overallLabel,
      'severity': instance.severity,
      'top_factors': instance.topFactors,
      'summary_sentence': instance.summarySentence,
      'base_value': instance.baseValue,
      'mode': instance.mode,
      'model_name': instance.modelName,
      'model_version': instance.modelVersion,
      'computed_at': instance.computedAt,
    };

_RiskFactor _$RiskFactorFromJson(Map<String, dynamic> json) => _RiskFactor(
  feature: json['feature'] as String,
  contribution: (json['contribution'] as num?)?.toDouble(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$RiskFactorToJson(_RiskFactor instance) =>
    <String, dynamic>{
      'feature': instance.feature,
      'contribution': instance.contribution,
      'label': instance.label,
    };

_RiskExplain _$RiskExplainFromJson(Map<String, dynamic> json) => _RiskExplain(
  segmentId: json['segment_id'] as String,
  baseValue: (json['base_value'] as num?)?.toDouble(),
  factors: (json['factors'] as List<dynamic>?)
      ?.map((e) => RiskFactor.fromJson(e as Map<String, dynamic>))
      .toList(),
  narrative: json['narrative'] as String?,
);

Map<String, dynamic> _$RiskExplainToJson(_RiskExplain instance) =>
    <String, dynamic>{
      'segment_id': instance.segmentId,
      'base_value': instance.baseValue,
      'factors': instance.factors,
      'narrative': instance.narrative,
    };
