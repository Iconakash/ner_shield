import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../models/alert.dart';
import '../../models/cached_result.dart';
import '../../models/notification_prefs.dart';

/// Alert inbox — role/RLS-scoped `GET /alerts/inbox` with a 30s cache.
/// Targeted routing means only the role currently holding an alert may
/// acknowledge it; the backend enforces this and 403s surface verbatim.
final alertsInboxProvider = AsyncNotifierProvider<AlertsController,
    CachedResult<List<Alert>>>(AlertsController.new);

class AlertsController
    extends AsyncNotifier<CachedResult<List<Alert>>> {
  @override
  Future<CachedResult<List<Alert>>> build() {
    return ref.watch(alertsRepositoryProvider).inbox();
  }

  /// Pull-to-refresh — explicit loading state (house pattern).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(alertsRepositoryProvider).inbox(),
    );
  }

  /// Silent refetch after acknowledge/resolve — keeps the list visible while
  /// the repository cache has already been invalidated.
  Future<void> reloadAfterAction() async {
    state = await AsyncValue.guard(
      () => ref.read(alertsRepositoryProvider).inbox(),
    );
  }
}

/// In-flight acknowledge/resolve feedback for the alerts screen.
class AlertActionState {
  const AlertActionState({this.busyId, this.message, this.error});

  final String? busyId;
  final String? message;
  final String? error;

  AlertActionState copyWith({
    String? busyId,
    String? message,
    String? error,
    bool clearBusy = false,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return AlertActionState(
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final alertActionProvider =
    NotifierProvider<AlertActionController, AlertActionState>(
      AlertActionController.new,
    );

class AlertActionController extends Notifier<AlertActionState> {
  @override
  AlertActionState build() => const AlertActionState();

  /// Acknowledge = take ownership; escalation pauses server-side.
  Future<bool> acknowledge(String alertId) async {
    state = state.copyWith(busyId: alertId, clearMessage: true, clearError: true);
    try {
      await ref.read(alertsRepositoryProvider).acknowledge(alertId);
      state = state.copyWith(
        clearBusy: true,
        message: 'Acknowledged — escalation paused.',
      );
      await ref.read(alertsInboxProvider.notifier).reloadAfterAction();
      return true;
    } catch (e, s) {
      final message = e is AppException
          ? e.message
          : 'Could not acknowledge the alert. Please try again.';
      state = state.copyWith(clearBusy: true, error: message);
      AppLogger.instance.error('alert acknowledge failed', e, s);
      return false;
    }
  }

  /// Resolve closes the alert; an optional note is stored server-side.
  Future<bool> resolve(String alertId, {String? note}) async {
    state = state.copyWith(busyId: alertId, clearMessage: true, clearError: true);
    try {
      await ref.read(alertsRepositoryProvider).resolve(alertId, note: note);
      state = state.copyWith(
        clearBusy: true,
        message: 'Alert resolved.',
      );
      await ref.read(alertsInboxProvider.notifier).reloadAfterAction();
      return true;
    } catch (e, s) {
      final message = e is AppException
          ? e.message
          : 'Could not resolve the alert. Please try again.';
      state = state.copyWith(clearBusy: true, error: message);
      AppLogger.instance.error('alert resolve failed', e, s);
      return false;
    }
  }
}

/// Notification preferences — always-fresh reads (see repository docs).
/// The screen only offers channels/severity the backend contract defines.
final notificationPrefsProvider = AsyncNotifierProvider<
    NotificationPrefsController, NotificationPreferences>(
  NotificationPrefsController.new,
);

class NotificationPrefsController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() {
    return ref.watch(notificationsRepositoryProvider).preferences();
  }

  /// Persists one channel toggle. Returns false (and keeps the previous
  /// state) when the backend rejects the change — a local-only toggle would
  /// mislead the user about what will actually be delivered.
  Future<bool> setChannel(String channel, {required bool enabled}) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final channels = Map<String, bool>.of(current.channels);
    channels[channel] = enabled;
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updatePreferences(current.copyWith(channels: channels));
      state = AsyncData(updated);
      return true;
    } catch (e, s) {
      AppLogger.instance.error('notification channel update failed', e, s);
      return false;
    }
  }

  /// Persists the minimum severity the backend should still deliver.
  Future<bool> setMinSeverity(String severity) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updatePreferences(current.copyWith(minSeverity: severity));
      state = AsyncData(updated);
      return true;
    } catch (e, s) {
      AppLogger.instance.error('notification severity update failed', e, s);
      return false;
    }
  }
}

/// Severity levels the preferences sheet offers (backend contract order).
const kMinSeverityChoices = <String>['INFO', 'WARNING', 'HIGH', 'CRITICAL'];
