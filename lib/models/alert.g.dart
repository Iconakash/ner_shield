// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Alert _$AlertFromJson(Map<String, dynamic> json) => _Alert(
  id: json['id'] as String,
  level: json['level'] as String?,
  alertType: json['alert_type'] as String?,
  title: json['title'] as String?,
  message: json['message'] as String?,
  status: json['status'] as String?,
  currentRole: json['current_role'] as String?,
  stateCode: json['state_code'] as String?,
  districtCode: json['district_code'] as String?,
  segmentId: json['segment_id'] as String?,
  shipmentId: json['shipment_id'] as String?,
  createdAt: json['created_at'] as String?,
  actedAt: json['acted_at'] as String?,
  localizedTitle: json['localized_title'] as String?,
  localizedMessage: json['localized_message'] as String?,
  emergencyInstruction: json['emergency_instruction'] as String?,
);

Map<String, dynamic> _$AlertToJson(_Alert instance) => <String, dynamic>{
  'id': instance.id,
  'level': instance.level,
  'alert_type': instance.alertType,
  'title': instance.title,
  'message': instance.message,
  'status': instance.status,
  'current_role': instance.currentRole,
  'state_code': instance.stateCode,
  'district_code': instance.districtCode,
  'segment_id': instance.segmentId,
  'shipment_id': instance.shipmentId,
  'created_at': instance.createdAt,
  'acted_at': instance.actedAt,
  'localized_title': instance.localizedTitle,
  'localized_message': instance.localizedMessage,
  'emergency_instruction': instance.emergencyInstruction,
};
