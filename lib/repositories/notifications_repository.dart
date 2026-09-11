import '../models/notification_prefs.dart';
import '../services/notifications_service.dart';

/// Preferences must always be fresh (a stale toggle would mislead the user
/// about what the backend will actually send), so this repository
/// deliberately does not cache.
class NotificationsRepository {
  NotificationsRepository(this._svc);

  final NotificationsService _svc;

  Future<NotificationPreferences> preferences() => _svc.preferences();

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  ) =>
      _svc.updatePreferences(prefs);
}