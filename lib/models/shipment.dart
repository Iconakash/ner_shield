import 'package:freezed_annotation/freezed_annotation.dart';

part 'shipment.freezed.dart';
part 'shipment.g.dart';

/// Shipment row from `GET /shipments` (reference `backend/app/shipments/router.py`).
///
/// Statuses: `VEHICLE_ASSIGNED | ROUTE_ASSIGNED | IN_TRANSIT | DELIVERED | CANCELLED`
/// Priority: `CRITICAL | HIGH | MEDIUM | NORMAL`
/// Commodity: `MEDICINE | EMERGENCY_SUPPLIES | WATER | EMERGENCY_FOOD | FOOD_GRAIN | FUEL | GENERAL`
@freezed
sealed class Shipment with _$Shipment {
  const Shipment._();
  const factory Shipment({
    required String id,
    String? code,
    String? title,
    String? commodity,
    String? priority,
    String? status,
    String? originName,
    String? destName,
    String? vehicleCode,
    String? destState,
    String? destDistrict,
    String? etaAt,
  }) = _Shipment;

  factory Shipment.fromJson(Map<String, dynamic> json) =>
      _$ShipmentFromJson(json);

  bool get isCritical => priority == 'CRITICAL';
  bool get isActive =>
      status == 'ROUTE_ASSIGNED' || status == 'IN_TRANSIT';
}

/// `GET /shipments/{id}/eta` — `{id, eta_minutes, calculated_at}`.
@freezed
sealed class ShipmentEta with _$ShipmentEta {
  const factory ShipmentEta({
    required String id,
    double? etaMinutes,
    String? calculatedAt,
  }) = _ShipmentEta;

  factory ShipmentEta.fromJson(Map<String, dynamic> json) =>
      _$ShipmentEtaFromJson(json);
}