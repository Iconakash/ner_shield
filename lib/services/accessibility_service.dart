import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/segment.dart';

/// Accessibility scoring reads (reference `backend/app/accessibility/router.py`).
class AccessibilityService {
  AccessibilityService(this._dio);

  final Dio _dio;

  /// GET /accessibility/segments — latest per-segment accessibility rows
  /// (`acc_classification`: OPEN | PARTIAL | CLOSED, plus acc_score + factors).
  Future<List<AccessibilitySegment>> segments({String? districtCode}) async {
    try {
      final res = await _dio.get<Object?>(
        '/accessibility/segments',
        queryParameters: {
          if (districtCode != null && districtCode.isNotEmpty)
            'district_code': districtCode,
        },
      );
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(AccessibilitySegment.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Accessibility rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}