import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/task.dart';

/// Action Center task API (`/tasks/*`).
///
/// Backend-driven transitions; the client surfaces the resulting status
/// verbatim and never fakes task state.
class TasksService {
  TasksService(this._dio);

  final Dio _dio;

  /// GET /tasks/mine — tasks assigned to the signed-in user.
  Future<List<TaskItem>> mine() async {
    try {
      final res = await _dio.get<Object?>('/tasks/mine');
      final body = requireJsonObject(res);
      final rows = body['tasks'];
      if (rows is! List) {
        throw const ParsingException('Tasks payload was malformed.');
      }
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(TaskItem.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Task rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /tasks/{id} — full task detail.
  Future<TaskItem> detail(String taskId) async {
    try {
      final res = await _dio.get<Object?>('/tasks/$taskId');
      final body = requireJsonObject(res);
      try {
        return TaskItem.fromJson(body);
      } on TypeError {
        throw const ParsingException('Task detail was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /tasks/{id}/transition — drive the workflow.
  /// Status set: ASSIGNED | ACCEPTED | IN_PROGRESS | BLOCKED | COMPLETED
  ///             | VERIFIED | CLOSED | CANCELLED.
  Future<TaskItem> transition(
    String taskId, {
    required String toStatus,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/tasks/$taskId/transition',
        data: <String, dynamic>{
          'to_status': toStatus,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final body = requireJsonObject(res);
      try {
        return TaskItem.fromJson(body);
      } on TypeError {
        throw const ParsingException('Task transition was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /field/reports/{id}/media/{mid}/url — signed URL for one media
  /// item (short-lived, never cached client-side).
  Future<FieldMedia> fieldMediaSignedUrl({
    required String reportId,
    required String mediaId,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/field/reports/$reportId/media/$mediaId/url',
      );
      final body = requireJsonObject(res);
      try {
        return FieldMedia.fromJson(body);
      } on TypeError {
        throw const ParsingException('Media signed URL response was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /intel/satellite/scenes?state=&district= — satellite evidence
  /// metadata.
  Future<List<SatelliteEvidence>> satelliteScenes({
    String? stateCode,
    String? districtCode,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/intel/satellite/scenes',
        queryParameters: <String, dynamic>{
          if (stateCode != null && stateCode.isNotEmpty) 'state': stateCode,
          if (districtCode != null && districtCode.isNotEmpty)
            'district': districtCode,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(SatelliteEvidence.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Satellite scenes payload was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}