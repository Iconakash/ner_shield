import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/responder.dart';

/// Responders + response task reads/writes (SIH26002 P3).
///
/// Authorization is enforced server-side (VIEW_INCIDENTS / MANAGE_SYSTEM);
/// the client only surfaces the resulting status codes.
class ResponderService {
  ResponderService(this._dio);

  final Dio _dio;

  /// GET /responders — RLS-scoped roster (district/type filters supported).
  Future<List<Responder>> list({String? district, String? type}) async {
    try {
      final res = await _dio.get<Object?>(
        '/responders',
        queryParameters: <String, dynamic>{
          if (district != null && district.isNotEmpty) 'district': district,
          if (type != null && type.isNotEmpty) 'rtype': type,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(Responder.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Responders payload was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /responders/nearest?lon=&lat=&limit=
  Future<List<Responder>> nearest({
    required double lon,
    required double lat,
    int limit = 5,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/responders/nearest',
        queryParameters: <String, dynamic>{
          'lon': lon,
          'lat': lat,
          'limit': limit,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(Responder.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Nearest responders payload was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /responders/{id}/notify — dispatch notification (MANAGE_SYSTEM).
  Future<ResponseTask> notifyResponder(String responderId, {String? note}) async {
    try {
      final res = await _dio.post<Object?>(
        '/responders/$responderId/notify',
        data: <String, dynamic>{'note': ?note},
      );
      final body = requireJsonObject(res);
      try {
        return ResponseTask.fromJson(body);
      } on TypeError {
        throw const ParsingException('Responder notify response was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /response-tasks/mine — response tasks assigned to me.
  Future<List<ResponseTask>> myTasks() async {
    try {
      final res = await _dio.get<Object?>('/response-tasks/mine');
      final body = requireJsonObject(res);
      final rows = body['tasks'];
      if (rows is! List) {
        throw const ParsingException('Response tasks payload was malformed.');
      }
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(ResponseTask.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Response tasks rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /response-tasks/{id}/transition — task status transition
  /// (`ACKNOWLEDGED | DISPATCHED | ON_SITE | RESOLVED | CANCELLED`).
  Future<ResponseTask> transition(
    String taskId, {
    required String status,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/response-tasks/$taskId/transition',
        data: <String, dynamic>{
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final body = requireJsonObject(res);
      try {
        return ResponseTask.fromJson(body);
      } on TypeError {
        throw const ParsingException('Response task transition was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}

/// Convenience: human-readable status labels.
String responderStatusLabel(String? status) {
  switch (status) {
    case 'STANDBY':
      return 'Standby';
    case 'NOTIFIED':
      return 'Notified';
    case 'DISPATCHED':
      return 'Dispatched';
    case 'ON_SITE':
      return 'On site';
    case 'RESOLVED':
      return 'Resolved';
    case 'ACKNOWLEDGED':
      return 'Acknowledged';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status ?? 'Unknown';
  }
}