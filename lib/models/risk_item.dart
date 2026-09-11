import 'package:freezed_annotation/freezed_annotation.dart';

part 'risk_item.freezed.dart';
part 'risk_item.g.dart';

/// Latest disruption-prediction row from `GET /risk/latest`
/// (reference `backend/app/risk/service.py`).
@freezed
sealed class RiskPrediction with _$RiskPrediction {
  const RiskPrediction._();
  const factory RiskPrediction({
    required String segmentId,
    String? roadCode,
    String? districtCode,
    String? districtName,
    double? riskCurrent,
    double? risk6h,
    double? risk12h,
    double? risk24h,
    double? risk72h,
    String? overallLabel,
    String? severity,
    // Nullable (not @Default): freezed 3.2.5 corrupts defaulted collection
    // parameters on the current SDK; callers use `?? const []`.
    List<Map<String, dynamic>>? topFactors,
    String? summarySentence,
    double? baseValue,
    String? mode,
    String? modelName,
    String? modelVersion,
    String? computedAt,
  }) = _RiskPrediction;

  factory RiskPrediction.fromJson(Map<String, dynamic> json) =>
      _$RiskPredictionFromJson(json);

  bool get isActionable =>
      overallLabel == 'HIGH' || overallLabel == 'CRITICAL';
}

/// One signed contribution inside a risk explanation.
@freezed
sealed class RiskFactor with _$RiskFactor {
  const factory RiskFactor({
    required String feature,
    double? contribution,
    String? label,
  }) = _RiskFactor;

  factory RiskFactor.fromJson(Map<String, dynamic> json) =>
      _$RiskFactorFromJson(json);
}

/// `GET /risk/{segment_id}/explain` — WHY card for a single segment.
@freezed
sealed class RiskExplain with _$RiskExplain {
  const factory RiskExplain({
    required String segmentId,
    double? baseValue,
    List<RiskFactor>? factors,
    String? narrative,
  }) = _RiskExplain;

  factory RiskExplain.fromJson(Map<String, dynamic> json) =>
      _$RiskExplainFromJson(json);
}