// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommandKpi _$CommandKpiFromJson(Map<String, dynamic> json) => _CommandKpi(
  id: json['id'] as String,
  count: (json['count'] as num).toInt(),
  description: json['description'] as String,
);

Map<String, dynamic> _$CommandKpiToJson(_CommandKpi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'count': instance.count,
      'description': instance.description,
    };

_CommandSummary _$CommandSummaryFromJson(
  Map<String, dynamic> json,
) => _CommandSummary(
  criticalAlerts: (json['critical_alerts'] as num?)?.toInt() ?? 0,
  highRiskRoads: (json['high_risk_roads'] as num?)?.toInt() ?? 0,
  activeShipments: (json['active_shipments'] as num?)?.toInt() ?? 0,
  criticalShipments: (json['critical_shipments'] as num?)?.toInt() ?? 0,
  supplyRiskDistricts: (json['supply_risk_districts'] as num?)?.toInt() ?? 0,
  predictedDisruptions: (json['predicted_disruptions'] as num?)?.toInt() ?? 0,
  generatedAt: json['generated_at'] as String?,
);

Map<String, dynamic> _$CommandSummaryToJson(_CommandSummary instance) =>
    <String, dynamic>{
      'critical_alerts': instance.criticalAlerts,
      'high_risk_roads': instance.highRiskRoads,
      'active_shipments': instance.activeShipments,
      'critical_shipments': instance.criticalShipments,
      'supply_risk_districts': instance.supplyRiskDistricts,
      'predicted_disruptions': instance.predictedDisruptions,
      'generated_at': instance.generatedAt,
    };
