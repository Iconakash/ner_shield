import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Action Center task row from `GET /tasks/mine`.
///
/// Status set: `ASSIGNED | ACCEPTED | IN_PROGRESS | BLOCKED |
///              COMPLETED | VERIFIED | CLOSED | CANCELLED`
/// Priority: `LOW | MEDIUM | HIGH | CRITICAL`
/// Source: `ALERT | INCIDENT | SHIPMENT | RISK | SUPPLY | MANUAL`
@freezed
sealed class TaskItem with _$TaskItem {
  const factory TaskItem({
    required String id,
    String? title,
    String? description,
    String? priority,
    String? status,
    @JsonKey(name: 'source_type') String? sourceType,
    @JsonKey(name: 'source_id') String? sourceId,
    @JsonKey(name: 'assignee_id') String? assigneeId,
    @JsonKey(name: 'state_code') String? stateCode,
    @JsonKey(name: 'district_code') String? districtCode,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) =>
      _$TaskItemFromJson(json);

  const TaskItem._();

  bool get isOpen =>
      status != 'COMPLETED' &&
      status != 'VERIFIED' &&
      status != 'CLOSED' &&
      status != 'CANCELLED';

  bool get isHighPriority =>
      priority == 'HIGH' || priority == 'CRITICAL';
}

/// A field media item (image / audio / document) attached to a field
/// report. Signed URL is short-lived and issued on demand by the backend.
@freezed
sealed class FieldMedia with _$FieldMedia {
  const factory FieldMedia({
    required String id,
    String? kind,
    String? filename,
    @JsonKey(name: 'mime_type') String? mimeType,
    int? sizeBytes,
    @JsonKey(name: 'uploaded_at') String? uploadedAt,
    String? signedUrl,
    @JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt,
  }) = _FieldMedia;

  factory FieldMedia.fromJson(Map<String, dynamic> json) =>
      _$FieldMediaFromJson(json);
}

/// Satellite evidence metadata row (SIH26002 P7).
@freezed
sealed class SatelliteEvidence with _$SatelliteEvidence {
  const factory SatelliteEvidence({
    required String id,
    String? sceneId,
    String? source,
    @JsonKey(name: 'captured_at') String? capturedAt,
    @JsonKey(name: 'state_code') String? stateCode,
    @JsonKey(name: 'district_code') String? districtCode,
    @JsonKey(name: 'cloud_cover_pct') double? cloudCoverPct,
    String? productType,
    String? signedUrl,
    @JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt,
  }) = _SatelliteEvidence;

  factory SatelliteEvidence.fromJson(Map<String, dynamic> json) =>
      _$SatelliteEvidenceFromJson(json);
}