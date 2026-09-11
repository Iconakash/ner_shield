import 'package:freezed_annotation/freezed_annotation.dart';

part 'segment.freezed.dart';
part 'segment.g.dart';

/// Accessibility row from `GET /accessibility/segments`
/// (reference `backend/app/accessibility/router.py`).
///
/// `acc_classification`: `OPEN | PARTIAL | CLOSED` (road vocabulary),
/// plus a numeric `acc_score` and contributing `factors`.
@freezed
sealed class AccessibilitySegment with _$AccessibilitySegment {
  const factory AccessibilitySegment({
    required String segmentId,
    String? accClassification,
    double? accScore,
    List<Map<String, dynamic>>? factors,
    String? updatedAt,
  }) = _AccessibilitySegment;

  factory AccessibilitySegment.fromJson(Map<String, dynamic> json) =>
      _$AccessibilitySegmentFromJson(json);
}