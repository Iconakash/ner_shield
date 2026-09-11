import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_report.freezed.dart';
part 'field_report.g.dart';

/// Field (incident) report from the backend.
///
/// Incident types (per `backend/app/field/reports/router.py`):
///   `LANDSLIDE | FLOOD | ROAD_DAMAGE | TRAFFIC_BLOCKAGE | BRIDGE_PROBLEM |
///    OTHER`
/// Severities: `LOW | MEDIUM | HIGH | CRITICAL`.
/// Statuses: `RECEIVED | UNDER_REVIEW | VALIDATED | REJECTED | IN_ACTION |
///   RESOLVED`.
/// Coordinate bounds: lon∈[80,98], lat∈[21,29.5] (NER region; surface to
/// officer when input falls outside).
@freezed
sealed class FieldReport with _$FieldReport {
  const FieldReport._();

  const factory FieldReport({
    required String id,
    String? code,
    String? incidentType,
    String? severity,
    String? status,
    String? description,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? roadCode,
    String? reporterId,
    String? reporterName,
    String? reportedAt,
    String? validatedAt,
    String? validatedBy,
    double? confidence,
    String? rejectReason,
    String? source,
    String? updatedAt,
    String? locationName,
    List<FieldReportMedia>? media,
  }) = _FieldReport;

  factory FieldReport.fromJson(Map<String, dynamic> json) =>
      _$FieldReportFromJson(json);

  bool get isOpen => status == 'RECEIVED' ||
      status == 'UNDER_REVIEW' ||
      status == 'VALIDATED' ||
      status == 'IN_ACTION';

  bool get isRejected => status == 'REJECTED';

  String get displayTitle =>
      '$incidentType'.toUpperCase().replaceAll('_', ' ');

  /// GPS-bounds check (per backend docs/api-contract-map.md):
  /// lon ∈ [80, 98], lat ∈ [21, 29.5].
  static bool withinBounds({required double lon, required double lat}) {
    return lon >= 80 && lon <= 98 && lat >= 21 && lat <= 29.5;
  }
}

/// Media metadata returned by `/field/reports/{id}/media`.
@freezed
sealed class FieldReportMedia with _$FieldReportMedia {
  const factory FieldReportMedia({
    required String id,
    String? contentType,
    int? byteSize,
    String? sha256,
    String? storagePath,
    bool? deduplicated,
    String? capturedAt,
    String? uploadedAt,
    String? localPath,
    // Server-relative URL is fetched on demand via
    // `/field/reports/{id}/media/{mid}/url` to avoid leaking signed URLs.
  }) = _FieldReportMedia;

  factory FieldReportMedia.fromJson(Map<String, dynamic> json) =>
      _$FieldReportMediaFromJson(json);
}

/// Phase 2 — a media reference attached to an offline draft. Persists on
/// the device until the parent FIELD_REPORT op reaches `synced` and the
/// media file actually uploads. `sha256` is computed lazily by the upload
/// worker; `sizeBytes` is recorded so the wizard can show upload progress
/// hints without re-reading the file.
@freezed
sealed class DraftMediaRef with _$DraftMediaRef {
  const factory DraftMediaRef({
    required String clientRefId,
    required String localPath,
    String? contentType,
    int? sizeBytes,
    String? sha256,
    String? capturedAt,
  }) = _DraftMediaRef;

  factory DraftMediaRef.fromJson(Map<String, dynamic> json) =>
      _$DraftMediaRefFromJson(json);
}

/// Local draft (Phase 9 wizard) — never sent to the server until the user
/// submits and connectivity is available. Mirrors [FieldReport] minus
/// server-issued fields.
@freezed
sealed class FieldReportDraft with _$FieldReportDraft {
  const FieldReportDraft._();

  const factory FieldReportDraft({
    required String clientDraftId,
    String? incidentType,
    String? severity,
    String? description,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? roadCode,
    String? locationName,
    double? lon,
    double? lat,
    String? createdAt,
    String? updatedAt,
    @Default(<String>[]) List<String> mediaPaths,
    /// Phase 2 — structured media refs (id + path + MIME + size + sha256).
    /// Preferred over the raw `mediaPaths` list for new code; the legacy
    /// list is kept for backwards compatibility with any code that still
    /// reads the raw paths.
    @Default(<DraftMediaRef>[]) List<DraftMediaRef> mediaRefs,
  }) = _FieldReportDraft;

  factory FieldReportDraft.fromJson(Map<String, dynamic> json) =>
      _$FieldReportDraftFromJson(json);

  /// True when every required field for a submission is populated.
  bool get isComplete =>
      incidentType != null &&
      severity != null &&
      lon != null &&
      lat != null;
}