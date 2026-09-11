import 'package:freezed_annotation/freezed_annotation.dart';

part 'routing_plan.freezed.dart';
part 'routing_plan.g.dart';

/// Route planner request payload — exactly the body accepted by the
/// backend `POST /routing/plan` (docs/api-contract-map.md §Accessibility /
/// Risk / Routing). Origin and destination each accept either a facility
/// code or raw lon/lat; the backend routing engine stays authoritative.
@freezed
sealed class RoutePlanRequest with _$RoutePlanRequest {
  const factory RoutePlanRequest({
    required RouteEndpoint origin,
    required RouteEndpoint destination,
    String? priority,
    double? riskAversion,
    int? k,
    String? mode,
    @JsonKey(name: 'avoid_segment_ids') List<String>? avoidSegmentIds,
  }) = _RoutePlanRequest;

  factory RoutePlanRequest.fromJson(Map<String, dynamic> json) =>
      _$RoutePlanRequestFromJson(json);
}

/// One routing endpoint: facility code XOR lon/lat.
@freezed
sealed class RouteEndpoint with _$RouteEndpoint {
  const factory RouteEndpoint({
    String? facilityCode,
    double? lon,
    double? lat,
  }) = _RouteEndpoint;

  factory RouteEndpoint.fromJson(Map<String, dynamic> json) =>
      _$RouteEndpointFromJson(json);

  const RouteEndpoint._();

  Map<String, dynamic> toBody() => facilityCode != null
      ? {'facility_code': facilityCode}
      : {'lon': lon, 'lat': lat};

  bool get isValid =>
      facilityCode != null || (lon != null && lat != null) ? true : false;

  String get displayLabel =>
      facilityCode ??
      '(${lon?.toStringAsFixed(4)}, ${lat?.toStringAsFixed(4)})';
}

/// One planned route as returned by the backend routing engine
/// (`POST /routing/plan` → `{routes:[...]}`). `rank` 1 is the engine's
/// recommendation; higher ranks are alternatives. The client NEVER
/// recomputes risk or ETA — it renders what the backend produced
/// (master prompt §29, §32).
@freezed
sealed class PlannedRoute with _$PlannedRoute {
  const factory PlannedRoute({
    required int rank,
    String? mode,
    @JsonKey(name: 'segments')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> segments,
    @JsonKey(name: 'total_distance_km') double? totalDistanceKm,
    @JsonKey(name: 'total_eta_minutes') double? totalEtaMinutes,
    @JsonKey(name: 'aggregate_risk') double? aggregateRisk,
    @JsonKey(name: 'aggregate_risk_label') String? aggregateRiskLabel,
    String? narrative,
  }) = _PlannedRoute;

  factory PlannedRoute.fromJson(Map<String, dynamic> json) =>
      _$PlannedRouteFromJson(json);

  const PlannedRoute._();

  bool get isRecommended => rank == 1;

  /// Human-readable risk band, falling back to the numeric score bucketed
  /// conservatively (labels always shown with numbers — non-color-only
  /// communication, master prompt §34).
  String get riskDisplay {
    final label = aggregateRiskLabel;
    if (label != null && label.isNotEmpty) return label;
    final r = aggregateRisk;
    if (r == null) return 'UNKNOWN';
    if (r < 0.25) return 'LOW';
    if (r < 0.5) return 'MODERATE';
    if (r < 0.75) return 'HIGH';
    return 'CRITICAL';
  }

  int get segmentCount => segments.length;
}

/// Response of `GET /routing/modes` → `{modes:[{id, description}]}`.
@freezed
sealed class RoutingMode with _$RoutingMode {
  const factory RoutingMode({required String id, required String description}) =
      _RoutingMode;

  factory RoutingMode.fromJson(Map<String, dynamic> json) =>
      _$RoutingModeFromJson(json);
}

/// The `/routing/plan` envelope: `{routes:[...]}`.
@freezed
sealed class RoutePlanResponse with _$RoutePlanResponse {
  const factory RoutePlanResponse({
    @JsonKey(name: 'routes')
    @Default(<PlannedRoute>[])
    List<PlannedRoute> routes,
  }) = _RoutePlanResponse;

  factory RoutePlanResponse.fromJson(Map<String, dynamic> json) =>
      _$RoutePlanResponseFromJson(json);

  const RoutePlanResponse._();

  List<PlannedRoute> get sortedByRank =>
      [...routes]..sort((a, b) => a.rank.compareTo(b.rank));
}
