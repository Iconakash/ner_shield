import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/risk_item.dart';

/// Risk prediction reads (reference `backend/app/risk/router.py`).
///
/// AI/ML stays server-side (master prompt §32) — the client renders the
/// backend's scores, labels, factors and model metadata verbatim.
class RiskService {
  RiskService(this._dio);

  final Dio _dio;

  /// GET /risk/latest — latest prediction per segment
  /// (optionally narrowed to one district; RLS-scoped).
  Future<List<RiskPrediction>> latest({String? districtCode}) async {
    try {
      final res = await _dio.get<Object?>(
        '/risk/latest',
        queryParameters: {
          if (districtCode != null && districtCode.isNotEmpty)
            'district_code': districtCode,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(RiskPrediction.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Risk rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /risk/{segment_id}/explain — WHY card for one segment.
  Future<RiskExplain> explain(String segmentId) async {
    try {
      final res = await _dio.get<Object?>('/risk/$segmentId/explain');
      final body = requireJsonObject(res);
      try {
        return RiskExplain.fromJson(body);
      } on TypeError {
        throw const ParsingException('Risk explanation was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}