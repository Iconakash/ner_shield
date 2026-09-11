import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/historical/historical_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/shell/app_shell.dart';

/// Central navigation config.
///
/// Routes:
///   /            landing (public)
///   /login       sign in (public — redirects to /shell if authenticated)
///   /shell/...   authenticated role shell
///
/// The authenticated-gate is backed by [authControllerProvider]; role-specific
/// sections are decided by the shell itself (display-only; server is the
/// authority).
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final signedIn = auth?.isAuthenticated ?? false;
      final location = state.matchedLocation;

      // Session restore in progress — hold at the landing gate.
      final loading = ref.read(authControllerProvider).isLoading;
      if (loading && location != '/') return '/';

      if (!signedIn) {
        if (location == '/' || location == '/login') return null;
        return '/login';
      }

      if (location == '/' || location == '/login') {
        return '/shell/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/shell/:section',
        builder: (context, state) {
          final section = state.pathParameters['section'] ?? 'dashboard';
          final focus = state.uri.queryParameters['focus'];
          return AppShell(location: section, focusId: focus);
        },
      ),
      GoRoute(
        path: '/shell/historical/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return HistoricalDetailScreen(eventId: eventId);
        },
      ),
    ],
  );
});

/// Notifies the router when the auth state changes so redirects re-run.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}