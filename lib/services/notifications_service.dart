import 'package:dio/dio.dart';

import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/notification_prefs.dart';

/// Notification preferences (reference `backend/app/notifications/router.py`).
///
/// Only the verified contract is implemented: GET/PUT
/// `/notifications/preferences` with `{channels: {}, min_severity}`.
/// The `/notifications` feed row schema is NOT yet verified against the
/// reference router, so no feed model is invented here (master prompt §8/§58);
/// the alerts inbox is the operational notification surface for now.
class NotificationsService {
  NotificationsService(this._dio);

  final Dio _dio;

  Future<NotificationPreferences> preferences() async {
    try {
      final res = await _dio.get<Object?>('/notifications/preferences');
      final body = requireJsonObject(res);
      return NotificationPreferences.fromJson(body);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      final res = await _dio.put<Object?>(
        '/notifications/preferences',
        data: prefs.toJson(),
      );
      final body = requireJsonObject(res);
      return NotificationPreferences.fromJson(body);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
