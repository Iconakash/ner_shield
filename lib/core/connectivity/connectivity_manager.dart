import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/error_mapper.dart';

/// Reusable [ConnectivityResult] stream provider.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

/// Derived connectivity class in the backend's vocabulary
/// (EXCELLENT|GOOD|WEAK|VERY_WEAK|OFFLINE) — docs/offline-strategy.md.
final connectivityClassProvider = Provider<String>((ref) {
  final snapshot = ref.watch(connectivityStreamProvider);
  final results = snapshot.value ?? [];
  return ErrorMapper.connectivityClass(results);
});

/// Convenience: whether we currently believe the device is offline.
final isOfflineProvider = Provider<bool>((ref) {
  final class_ = ref.watch(connectivityClassProvider);
  return class_ == 'OFFLINE';
});