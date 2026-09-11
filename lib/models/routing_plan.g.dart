// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routing_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoutePlanRequest _$RoutePlanRequestFromJson(Map<String, dynamic> json) =>
    _RoutePlanRequest(
      origin: RouteEndpoint.fromJson(json['origin'] as Map<String, dynamic>),
      destination: RouteEndpoint.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      priority: json['priority'] as String?,
      riskAversion: (json['risk_aversion'] as num?)?.toDouble(),
      k: (json['k'] as num?)?.toInt(),
      mode: json['mode'] as String?,
      avoidSegmentIds: (json['avoid_segment_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RoutePlanRequestToJson(_RoutePlanRequest instance) =>
    <String, dynamic>{
      'origin': instance.origin,
      'destination': instance.destination,
      'priority': instance.priority,
      'risk_aversion': instance.riskAversion,
      'k': instance.k,
      'mode': instance.mode,
      'avoid_segment_ids': instance.avoidSegmentIds,
    };

_RouteEndpoint _$RouteEndpointFromJson(Map<String, dynamic> json) =>
    _RouteEndpoint(
      facilityCode: json['facility_code'] as String?,
      lon: (json['lon'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RouteEndpointToJson(_RouteEndpoint instance) =>
    <String, dynamic>{
      'facility_code': instance.facilityCode,
      'lon': instance.lon,
      'lat': instance.lat,
    };

_PlannedRoute _$PlannedRouteFromJson(Map<String, dynamic> json) =>
    _PlannedRoute(
      rank: (json['rank'] as num).toInt(),
      mode: json['mode'] as String?,
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      totalEtaMinutes: (json['total_eta_minutes'] as num?)?.toDouble(),
      aggregateRisk: (json['aggregate_risk'] as num?)?.toDouble(),
      aggregateRiskLabel: json['aggregate_risk_label'] as String?,
      narrative: json['narrative'] as String?,
    );

Map<String, dynamic> _$PlannedRouteToJson(_PlannedRoute instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'mode': instance.mode,
      'segments': instance.segments,
      'total_distance_km': instance.totalDistanceKm,
      'total_eta_minutes': instance.totalEtaMinutes,
      'aggregate_risk': instance.aggregateRisk,
      'aggregate_risk_label': instance.aggregateRiskLabel,
      'narrative': instance.narrative,
    };

_RoutingMode _$RoutingModeFromJson(Map<String, dynamic> json) => _RoutingMode(
  id: json['id'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$RoutingModeToJson(_RoutingMode instance) =>
    <String, dynamic>{'id': instance.id, 'description': instance.description};

_RoutePlanResponse _$RoutePlanResponseFromJson(Map<String, dynamic> json) =>
    _RoutePlanResponse(
      routes:
          (json['routes'] as List<dynamic>?)
              ?.map((e) => PlannedRoute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PlannedRoute>[],
    );

Map<String, dynamic> _$RoutePlanResponseToJson(_RoutePlanResponse instance) =>
    <String, dynamic>{'routes': instance.routes};
