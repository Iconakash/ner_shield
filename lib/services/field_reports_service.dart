import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/field_report.dart';
import '../models/sync_models.dart';

/// Field intel reads/writes (reference `backend/app/field/reports/router.py`).
///
/// Authorization is enforced server-side per operation (CREATE_INCIDENT,
/// VERIFY_INCIDENT, VIEW_INCIDENTS); the client only surfaces the resulting
/// status codes.
///
/// Important contract (docs/api-contract-map.md §Field intel):
/// - `incident_type` ∈ {LANDSLIDE, FLOOD, ROAD_DAMAGE, TRAFFIC_BLOCKAGE,
///   BRIDGE_PROBLEM, OTHER}
/// - `severity` ∈ {LOW, MEDIUM, HIGH, CRITICAL}
/// - lon ∈ [80, 98], lat ∈ [21, 29.5]
/// - Media via separate `/field/reports/{id}/media` multipart upload (≤10MiB)
/// - Validation queue is role-gated (VERIFY_INCIDENT)
class FieldReportsService {
  FieldReportsService(this._dio);

  final Dio _dio;

  /// GET /field/reports/mine â€” my reports.
  Future<List<FieldReport>> mine() async {
    return _list('/field/reports/mine');
  }

  /// GET /field/reports/queue â€” verification queue (VERIFY_INCIDENT).
  Future<List<FieldReport>> queue() async {
    return _list('/field/reports/queue');
  }

  /// GET /field/reports/{id}/detail â€” single report incl. media + confidence.
  Future<FieldReport> detail(String id) async {
    try {
      final res = await _dio.get<Object?>('/field/reports/$id/detail');
      return FieldReport.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /field/reports â€” create (returns code, confidence).
  Future<FieldReport> create({
    required String incidentType,
    required String severity,
    required double lon,
    required double lat,
    String? description,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? roadCode,
    String? locationName,
    String? source,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/field/reports',
        data: {
          'incident_type': incidentType,
          'severity': severity,
          'lon': lon,
          'lat': lat,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (stateCode != null && stateCode.isNotEmpty)
            'state_code': stateCode,
          if (districtCode != null && districtCode.isNotEmpty)
            'district_code': districtCode,
          if (segmentId != null && segmentId.isNotEmpty)
            'segment_id': segmentId,
          if (roadCode != null && roadCode.isNotEmpty) 'road_code': roadCode,
          if (locationName != null && locationName.isNotEmpty)
            'location_name': locationName,
          if (source != null && source.isNotEmpty) 'source': source,
        },
      );
      return FieldReport.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

/// POST /field/reports/{id}/validate â€” VALIDATED / REJECTED.
  Future<FieldReport> validate(
    String id, {
    required String decision,
    String? reason,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/field/reports/$id/validate',
        data: {
          'decision': decision,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return FieldReport.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /field/reporters/{id}/trust â€” reporter trust ledger.
  Future<Map<String, dynamic>> reporterTrust(String reporterId) async {
    try {
      final res = await _dio.get<Object?>('/field/reporters/$reporterId/trust');
      return requireJsonObject(res);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /field/reports/{id}/media â€” multipart file upload (≤10 MiB).
  Future<FieldReportMedia> uploadMedia({
    required String reportId,
    required String localPath,
    String? contentType,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: localPath.split('/').last,
        ),
        if (contentType != null && contentType.isNotEmpty)
          'content_type': contentType,
      });
      final res = await _dio.post<Object?>(
        '/field/reports/$reportId/media',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return FieldReportMedia.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /field/reports/{id}/media â€” list media for one report.
  Future<List<FieldReportMedia>> listMedia(String reportId) async {
    try {
      final res = await _dio.get<Object?>('/field/reports/$reportId/media');
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(FieldReportMedia.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Media rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /sync/push â€” batched offline operations (typed convenience).
  Future<SyncPushResponse> pushOps({
    required String connectivity,
    required List<SyncPushOp> ops,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/sync/push',
        data: {
          'connectivity': connectivity,
          'ops': ops.map((o) => o.toJson()).toList(),
        },
      );
      return SyncPushResponse.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<List<FieldReport>> _list(String path) async {
    try {
      final res = await _dio.get<Object?>(path);
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(FieldReport.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Field report rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
