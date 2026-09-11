import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/route_graph_snapshot.dart';
import '../models/routing_plan.dart';

/// Routing reads (reference `backend/app/risk/router.py` — routing endpoints
/// are served by the risk router in the reference backend).
///
/// The backend routing engine is authoritative (master prompt §29): the
/// client requests a plan and renders the response; it never recomputes
/// routes, risk, or ETA.
class RoutingService {
  RoutingService(this._dio);

  final Dio _dio;

  /// GET /routing/modes — the planning modes this deployment supports.
  Future<List<RoutingMode>> modes() async {
    try {
      final res = await _dio.get<Object?>('/routing/modes');
      final body = requireJsonObject(res);
      final rows = body['modes'];
      if (rows is! List) {
        throw const ParsingException('Routing modes were malformed.');
      }
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(RoutingMode.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Routing modes were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /routing/plan — plan a route with alternatives through the
  /// backend engine. Always live; responses are never cached (road state,
  /// risk and incidents change between calls).
  Future<RoutePlanResponse> plan(RoutePlanRequest request) async {
    try {
      final body = <String, dynamic>{
        'origin': request.origin.toBody(),
        'destination': request.destination.toBody(),
        'priority': ?request.priority,
        'risk_aversion': ?request.riskAversion,
        'k': ?request.k,
        'mode': ?request.mode,
        'avoid_segment_ids': ?request.avoidSegmentIds,
      };
      final res = await _dio.post<Object?>('/routing/plan', data: body);
      final json = requireJsonObject(res);
      try {
        return RoutePlanResponse.fromJson(json);
      } on TypeError {
        throw const ParsingException('Route plan response was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /routing/graph-snapshot — Phase 5 additive endpoint carrying the
  /// SAME edge weights the authoritative /routing/plan engine uses. The
  /// offline layer persists this so planning can continue without network.
  Future<RouteGraphSnapshot> graphSnapshot() async {
    try {
      final res = await _dio.get<Object?>('/routing/graph-snapshot');
      final json = requireJsonObject(res);
      try {
        return RouteGraphSnapshot.fromJson(json);
      } on TypeError {
        throw const ParsingException('Graph snapshot was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
