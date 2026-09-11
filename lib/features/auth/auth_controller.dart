import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';

/// Provides the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(dioProvider),
    ref.watch(secureTokenStorageProvider),
  );
});

/// Session state.
///
/// `pure` = signed-out; `mfa` = first factor accepted, TOTP verification
/// pending; `ready` = signed-in with a resolved principal (role from the
/// server /auth/me).
class AuthState {
  const AuthState.ready(this.principal)
      : assert(principal != null),
        mfaPending = false;

  /// Signed-out state.
  const AuthState.pure() : principal = null, mfaPending = false;

  /// First-factor accepted; the MFA challenge is in flight.
  const AuthState.mfa() : principal = null, mfaPending = true;

  final AppPrincipal? principal;
  final bool mfaPending;

  bool get isAuthenticated => principal != null;
}

/// Authentication controller — launch → restore → login → profile →
/// role resolution → shell (docs/workflow-map.md §0-1).
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  /// Bound session-expiry handler. One closure instance so identity checks are
  /// stable.
  late final Future<void> Function() _sessionExpiryHandler;

  /// Cached controller for the global handler — captured at build time so the
  /// lifetime of the wiring matches this provider and the shared Dio (both
  /// die with the same ProviderContainer).
  late final StateController<Future<void> Function()?> _sessionExpirySetter;

  @override
  Future<AuthState> build() async {
    _sessionExpiryHandler = () => expire();
    _sessionExpirySetter = ref.read(sessionExpiryHandlerProvider.notifier);
    // Wiring must happen after this provider settles — Riverpod forbids
    // mutating another provider while a provider is building.
    scheduleMicrotask(() {
      _sessionExpirySetter.state = _sessionExpiryHandler;
    });

    final tokens = ref.watch(secureTokenStorageProvider);
    final has = await tokens.hasSession;
    if (!has) {
      await tokens.clear();
      await tokens.clearMfaMarker();
      return const AuthState.pure();
    }
    // Session present → attempt a headless restore.
    try {
      final principal = await ref.read(authServiceProvider).me();
      return AuthState.ready(principal);
    } on AppException catch (e) {
      AppLogger.instance.warn('session restore failed: ${e.code}');
      if (e.retryable) {
        rethrow;
      }
      await tokens.clear();
      await tokens.clearMfaMarker();
      return const AuthState.pure();
    } catch (e, s) {
      AppLogger.instance.error('unexpected restore error', e, s);
      await tokens.clear();
      await tokens.clearMfaMarker();
      return const AuthState.pure();
    }
  }

  /// First factor (credentials). Returns `true` when fully authenticated;
  /// `false` when MFA verification is required (state becomes `AuthState.mfa`).
  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(authServiceProvider);
      final result = await service.login(email: email, password: password);
      if (result.mfaRequired) {
        state = const AsyncData(AuthState.mfa());
        return false;
      }
      final principal = await service.me();
      state = AsyncData(AuthState.ready(principal));
      return true;
    } catch (e, s) {
      AppLogger.instance.error('sign-in failed', e, s);
      state = AsyncError(e, s);
      rethrow;
    }
  }

  /// Second factor (TOTP). Runs challenge → verify against the pending
  /// first-factor session, then resolves the principal via /auth/me.
  Future<void> verifyMfa({required String code}) async {
    final current = state.valueOrNull;
    if (current == null || !current.mfaPending) {
      throw const ValidationException('No MFA challenge is pending.');
    }
    state = const AsyncLoading();
    try {
      final service = ref.read(authServiceProvider);
      final challenge = await service.mfaChallenge();
      await service.mfaVerify(
        factorId: challenge.factorId,
        challengeId: challenge.challengeId,
        code: code,
        accountEmail: await ref.read(secureTokenStorageProvider).accountEmail,
      );
      final principal = await service.me();
      state = AsyncData(AuthState.ready(principal));
    } catch (e, s) {
      AppLogger.instance.error('MFA verification failed', e, s);
      state = AsyncError(e, s);
      rethrow;
    }
  }

  /// Abandon a pending MFA challenge and return to signed-out (used by the
  /// "use a different account" affordance; also clears the first-factor
  /// marker).
  Future<void> cancelMfa() async {
    await ref.read(secureTokenStorageProvider).clearMfaMarker();
    state = const AsyncData(AuthState.pure());
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).logout();
    await ref.read(secureTokenStorageProvider).clearMfaMarker();
    state = const AsyncData(AuthState.pure());
  }

  /// Global handler invoked when the shared Dio observes a 401. The backend
  /// exposes no refresh route (contract gap — see current-state audit), so an
  /// expired session degrades to a clean sign-out; screens surface the 401 via
  /// their own error states and the router redirects to login.
  Future<void> expire() async {
    final current = state.valueOrNull;
    if (current == null || !current.isAuthenticated) return;
    AppLogger.instance.info('session expired — clearing local session');
    await ref.read(secureTokenStorageProvider).clear();
    await ref.read(secureTokenStorageProvider).clearMfaMarker();
    state = const AsyncData(AuthState.pure());
  }

  /// After any foreground/resume, re-verify the session is still valid and
  /// role/permissions haven't changed server-side.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null || !current.isAuthenticated) return;
    try {
      final principal = await ref.read(authServiceProvider).me();
      state = AsyncData(AuthState.ready(principal));
    } on AppException {
      // Keep the last known session; the server will reject stale tokens on
      // the next protected call (401 → [expire]).
    }
  }
}

/// Derived: whether a live session currently exists. The Phase-11
/// reconciliation coordinator gates every automatic sync trigger on this —
/// flushing the queue or pulling deltas while signed out would only burn
/// attempts (401) or mark entries failed.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.valueOrNull?.isAuthenticated ?? false;
});