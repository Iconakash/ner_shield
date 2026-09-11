// Phase 4 §4.4 — OfflineMapBanner UI widget test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/connectivity/connectivity_manager.dart';
import 'package:ner_shield/core/maps/offline_tile_cache.dart';
import 'package:ner_shield/features/maps/offline_map_banner.dart';

void main() {
  group('Phase 4 — OfflineMapBanner', () {
    testWidgets('hidden when online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityClassProvider.overrideWithValue('GOOD'),
          ],
          child: const MaterialApp(
            home: Scaffold(body: OfflineMapBanner()),
          ),
        ),
      );
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('shows cached-tile stats when offline', (tester) async {
      final summary = OfflineTileCacheSummary(
        tilesCached: 42,
        bytesCached: 3 * 1024 * 1024,
        bytesBudget: 200 * 1024 * 1024,
        templateHash: 'h',
        lastUpdated: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityClassProvider.overrideWithValue('OFFLINE'),
            offlineMapStatsProvider.overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(
            home: Scaffold(body: OfflineMapBanner()),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.textContaining('42 tiles'), findsOneWidget);
      expect(find.textContaining('2 h ago'), findsOneWidget);
    });
  });
}