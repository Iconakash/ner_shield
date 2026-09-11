import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/command_summary.dart';
import '../models/geojson.dart';

/// Command Center reads (reference `backend/app/command/router.py`).
///
/// Read-only awareness surface: every route requires VIEW_MAP and the
/// caller's RLS scope drives what comes back — the client never scopes.
class CommandService {
  CommandService(this._dio);

  final Dio _dio;

  /// GET /command/summary — the frozen six KPI tiles, RLS-scoped.
  Future<CommandSummary> summary() async {
    try {
      final res = await _dio.get<Object?>('/command/summary');
      final body = requireJsonObject(res);
      try {
        return CommandSummary.fromJson(body);
      } on TypeError {
        throw const ParsingException('Command summary was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /command/layers/{name} — live map layer as GeoJSON
  /// (`high-risk-roads`, `disruptions`, `shipments`, `weather`).
  Future<GeoJsonFeatureCollection> layer(String name) async {
    try {
      final res = await _dio.get<Object?>('/command/layers/$name');
      return GeoJsonFeatureCollection.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}