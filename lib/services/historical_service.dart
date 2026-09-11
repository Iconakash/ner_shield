import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/historical_event.dart';

/// Historical validation reads (P4 historical analytics).
///
/// All responses are *always* labelled with `data_quality` and
/// `dataset_version` server-side; the client renders those verbatim so a
/// SAMPLE/SIMULATED run cannot be confused with a MEASURED result (master
/// prompt §42: never fabricate analytics).
class HistoricalService {
  HistoricalService(this._dio);

  final Dio _dio;

  /// GET /historical/events — events visible to the caller's RLS scope.
  Future<List<HistoricalEvent>> events() async {
    try {
      final res = await _dio.get<Object?>('/historical/events');
      final body = requireJsonObject(res);
      final rows = body['events'];
      if (rows is! List) {
        throw const ParsingException('Historical events payload was malformed.');
      }
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(HistoricalEvent.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Historical events rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /historical/events/{id} — event detail + observations + latest run.
  Future<HistoricalEvent> eventDetail(String eventId) async {
    try {
      final res = await _dio.get<Object?>('/historical/events/$eventId');
      final body = requireJsonObject(res);
      try {
        return HistoricalEvent.fromJson(body);
      } on TypeError {
        throw const ParsingException('Historical event detail was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /historical/validation/{eventId} — latest validation run for an
  /// event. The server returns 404 when none exists; the client surfaces
  /// this as `NotFoundException` rather than fabricating metrics.
  Future<HistoricalValidationRun> latestValidation(String eventId) async {
    try {
      final res = await _dio.get<Object?>('/historical/validation/$eventId');
      final body = requireJsonObject(res);
      try {
        return HistoricalValidationRun.fromJson(body);
      } on TypeError {
        throw const ParsingException('Historical validation row was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /historical/validation/run/{eventId} — replay a validation run
  /// (MANAGE_SYSTEM). Server-authoritative: the body shape is server-defined.
  Future<HistoricalValidationRun> runValidation(String eventId) async {
    try {
      final res = await _dio.post<Object?>(
        '/historical/validation/run/$eventId',
      );
      final body = requireJsonObject(res);
      try {
        return HistoricalValidationRun.fromJson(body);
      } on TypeError {
        throw const ParsingException(
          'Historical validation run response was malformed.',
        );
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}