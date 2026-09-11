import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/realtime/sse_client.dart';
import '../auth/auth_controller.dart';

/// Single shared `SseClient` instance so the reconnection reconciler
/// (and other controllers) can drive a reconnect explicitly instead of
/// relying on the implicit retry timer inside `realtimeStreamProvider`.
final sseClientProvider = Provider<SseClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokens = ref.watch(secureTokenStorageProvider);
  final client = SseClient(
    baseUrl: config.apiBaseUrl,
    accessTokenProvider: () => tokens.accessToken,
  );
  ref.onDispose(client.stop);

  // Reconnect when the authenticated session transitions to a valid state.
  ref.listen<AsyncValue<AuthState>>(authControllerProvider, (_, next) {
    final authed = next.valueOrNull?.isAuthenticated ?? false;
    if (!authed) {
      unawaited(client.stop());
    } else {
      unawaited(client.reconnectNow());
    }
  });
  return client;
});

/// Broadcast realtime stream exposed to the rest of the app.
final realtimeStreamProvider = StreamProvider<RealtimeEvent>((ref) {
  final client = ref.watch(sseClientProvider);
  unawaited(client.connect());
  return client.stream;
});

/// Dedup helper — tracks the last N event ids seen so duplicate server
/// deliveries don't trigger redundant controller reloads.
class RealtimeDedup {
  RealtimeDedup({this.maxSize = 256});

  final int maxSize;
  final Set<String> _seen = <String>{};
  final List<String> _order = <String>[];

  bool consume(String id) {
    if (id.isEmpty) return true;
    if (_seen.contains(id)) return false;
    _seen.add(id);
    _order.add(id);
    if (_order.length > maxSize) {
      _seen.remove(_order.removeAt(0));
    }
    return true;
  }
}

/// App-wide dedup instance (recreated on dispose).
final realtimeDedupProvider = Provider<RealtimeDedup>((ref) {
  return RealtimeDedup();
});