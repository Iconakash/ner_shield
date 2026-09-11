// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Responder _$ResponderFromJson(Map<String, dynamic> json) => _Responder(
  id: json['id'] as String,
  name: json['name'] as String?,
  responderType: json['responder_type'] as String?,
  operationalStatus: json['operational_status'] as String?,
  districtCode: json['district_code'] as String?,
  stateCode: json['state_code'] as String?,
  contactMethod: json['contact_method'] as String?,
  isDemo: json['is_demo'] as bool?,
  escalationPriority: (json['escalation_priority'] as num?)?.toInt(),
  geo: json['geo'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ResponderToJson(_Responder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'responder_type': instance.responderType,
      'operational_status': instance.operationalStatus,
      'district_code': instance.districtCode,
      'state_code': instance.stateCode,
      'contact_method': instance.contactMethod,
      'is_demo': instance.isDemo,
      'escalation_priority': instance.escalationPriority,
      'geo': instance.geo,
    };

_ResponseTask _$ResponseTaskFromJson(Map<String, dynamic> json) =>
    _ResponseTask(
      id: json['id'] as String,
      responderId: json['responder_id'] as String?,
      responderName: json['responder_name'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      relatedAlertId: json['related_alert_id'] as String?,
      relatedShipmentId: json['related_shipment_id'] as String?,
      createdAt: json['created_at'] as String?,
      completedAt: json['completed_at'] as String?,
    );

Map<String, dynamic> _$ResponseTaskToJson(_ResponseTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'responder_id': instance.responderId,
      'responder_name': instance.responderName,
      'priority': instance.priority,
      'status': instance.status,
      'title': instance.title,
      'description': instance.description,
      'related_alert_id': instance.relatedAlertId,
      'related_shipment_id': instance.relatedShipmentId,
      'created_at': instance.createdAt,
      'completed_at': instance.completedAt,
    };
