// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shipment _$ShipmentFromJson(Map<String, dynamic> json) => _Shipment(
  id: json['id'] as String,
  code: json['code'] as String?,
  title: json['title'] as String?,
  commodity: json['commodity'] as String?,
  priority: json['priority'] as String?,
  status: json['status'] as String?,
  originName: json['origin_name'] as String?,
  destName: json['dest_name'] as String?,
  vehicleCode: json['vehicle_code'] as String?,
  destState: json['dest_state'] as String?,
  destDistrict: json['dest_district'] as String?,
  etaAt: json['eta_at'] as String?,
);

Map<String, dynamic> _$ShipmentToJson(_Shipment instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'title': instance.title,
  'commodity': instance.commodity,
  'priority': instance.priority,
  'status': instance.status,
  'origin_name': instance.originName,
  'dest_name': instance.destName,
  'vehicle_code': instance.vehicleCode,
  'dest_state': instance.destState,
  'dest_district': instance.destDistrict,
  'eta_at': instance.etaAt,
};

_ShipmentEta _$ShipmentEtaFromJson(Map<String, dynamic> json) => _ShipmentEta(
  id: json['id'] as String,
  etaMinutes: (json['eta_minutes'] as num?)?.toDouble(),
  calculatedAt: json['calculated_at'] as String?,
);

Map<String, dynamic> _$ShipmentEtaToJson(_ShipmentEta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eta_minutes': instance.etaMinutes,
      'calculated_at': instance.calculatedAt,
    };
