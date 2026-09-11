import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/connectivity/connectivity_manager.dart';

/// Phase 4 §4.4 — small status strip shown over the map while offline.
///
/// Clearly signals that the map is operating on locally cached raster
/// tiles and never pretends it is live: it shows the connectivity class,
/// the number of cached tiles, the bytes used, and the age of the most
/// recent tile fetch. Hidden entirely when online (the map is live then).
class OfflineMapBanner extends ConsumerWidget {
  const OfflineMapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityClassProvider);
    final offline = connectivity == 'OFFLINE';
    if (!offline) return const SizedBox.shrink();

    final stats = ref.watch(offlineMapStatsProvider);
    final theme = Theme.of(context);

    final (tilesLabel, bytesLabel, ageLabel) = switch (stats) {
      AsyncData(:final value) => (
          '${value.tilesCached}',
          _formatBytes(value.bytesCached),
          value.lastUpdated == null
              ? 'no cached tiles yet'
              : 'cached ${_timeAgo(value.lastUpdated!)}',
        ),
      AsyncError(:final error) => ('?', '?', 'cache status unavailable'),
      _ => ('…', '…', 'checking cache…'),
    };

    return Material(
      color: theme.colorScheme.inverseSurface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off,
                size: 16, color: theme.colorScheme.onInverseSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline — $tilesLabel tiles · $bytesLabel ($ageLabel). '
                'Map shows cached data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int b) {
    if (b >= 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    if (b >= 1024) {
      return '${(b / 1024).toStringAsFixed(0)} KiB';
    }
    return '$b B';
  }

  static String _timeAgo(DateTime at) {
    final diff = DateTime.now().toUtc().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return '${diff.inDays ~/ 30} mo ago';
  }
}