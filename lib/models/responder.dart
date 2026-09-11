import 'package:freezed_annotation/freezed_annotation.dart';

part 'responder.freezed.dart';
part 'responder.g.dart';

/// Responder roster row from `GET /responders` (SIH26002 P3).
///
/// Contact method values: `DISPATCH_RADIO | PHONE | SATELLITE_PHONE | APP`
/// Status values: `STANDBY | NOTIFIED | DISPATCHED | ON_SITE | RESOLVED`
@freezed
sealed class Responder with _$Responder {
  const factory Responder({
    required String id,
    String? name,
    @JsonKey(name: 'responder_type') String? responderType,
    @JsonKey(name: 'operational_status') String? operationalStatus,
    @JsonKey(name: 'district_code') String? districtCode,
    @JsonKey(name: 'state_code') String? stateCode,
    @JsonKey(name: 'contact_method') String? contactMethod,
    @JsonKey(name: 'is_demo') bool? isDemo,
    @JsonKey(name: 'escalation_priority') int? escalationPriority,
    Map<String, dynamic>? geo,
  }) = _Responder;

  factory Responder.fromJson(Map<String, dynamic> json) =>
      _$ResponderFromJson(json);

  const Responder._();

  /// Demo-flagged rows must never appear in operational dashboards without
  /// an explicit DEMO label (master prompt §42: never present fake data as
  /// real).
  bool get isDemoRow => isDemo ?? false;

  bool get isAvailable =>
      operationalStatus == 'STANDBY' || operationalStatus == null;
}

/// One responder response task (action center). The backend drives the
/// transitions; the client surfaces the resulting status verbatim.
@freezed
sealed class ResponseTask with _$ResponseTask {
  const factory ResponseTask({
    required String id,
    @JsonKey(name: 'responder_id') String? responderId,
    @JsonKey(name: 'responder_name') String? responderName,
    String? priority,
    String? status,
    String? title,
    String? description,
    @JsonKey(name: 'related_alert_id') String? relatedAlertId,
    @JsonKey(name: 'related_shipment_id') String? relatedShipmentId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _ResponseTask;

  factory ResponseTask.fromJson(Map<String, dynamic> json) =>
      _$ResponseTaskFromJson(json);

  const ResponseTask._();

  bool get isOpen => status != 'RESOLVED' && status != 'CANCELLED';
}