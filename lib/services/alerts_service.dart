import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/alert.dart';

/// Alert inbox + lifecycle (reference `backend/app/alerts/router.py`).
///
/// Targeted routing: only the role currently holding the alert (or
/// SUPER_ADMIN) may acknowledge — the backend enforces this; treat 403s as
/// authorization explanations, never retry loops.
class AlertsService {
  AlertsService(this._dio);

  final Dio _dio;

  /// GET /alerts/inbox — RLS/role-scoped; `?lang=` returns localized copies.
  Future<List<Alert>> inbox({int limit = 100, String? lang}) async {
    try {
      final res = await _dio.get<Object?>(
        '/alerts/inbox',
        queryParameters: {
          'limit': limit,
          if (lang != null && lang.isNotEmpty) 'lang': lang,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(Alert.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Alert rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /alerts/{id}/acknowledge — stops escalation.
  Future<void> acknowledge(String alertId) async {
    await _post('/alerts/$alertId/acknowledge');
  }

  /// POST /alerts/{id}/resolve — optional resolution note.
  Future<void> resolve(String alertId, {String? note}) async {
    await _post(
      '/alerts/$alertId/resolve',
      data: {if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  Future<void> _post(String path, {Object? data}) async {
    try {
      final res = await _dio.post<Object?>(path, data: data);
      requireJsonObject(res);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}