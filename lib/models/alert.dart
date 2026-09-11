import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

/// Alert row from `GET /alerts/inbox` (reference `backend/app/alerts/service.py`).
///
/// Levels: `INFO | WARNING | HIGH | CRITICAL`
/// Types: `ROAD_WARNING | CRITICAL_SHIPMENT | REGIONAL_SUPPLY_CRISIS |
///         DISRUPTION_PREDICTED | SHORTAGE_PREDICTED | IMPACT_ALERT | SYSTEM`
/// Statuses: `ACTIVE | ESCALATED | ACKNOWLEDGED | VALIDATED | MITIGATED |
///            RESOLVED | CLOSED`
@freezed
sealed class Alert with _$Alert {
  const Alert._();
  const factory Alert({
    required String id,
    String? level,
    String? alertType,
    String? title,
    String? message,
    String? status,
    String? currentRole,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? shipmentId,
    String? createdAt,
    String? actedAt,
    // Localized fields (Phase 17) when ?lang= is requested.
    String? localizedTitle,
    String? localizedMessage,
    String? emergencyInstruction,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) =>
      _$AlertFromJson(json);

  bool get isOpen => status == 'ACTIVE' || status == 'ESCALATED';

  String get displayTitle => localizedTitle ?? title ?? 'Untitled alert';
}