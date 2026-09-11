import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/features/maps/map_layers.dart';
import 'package:ner_shield/features/maps/map_screen.dart';

import 'phase8_map_fakes.dart';

/// Stub HTTP client so flutter_map's `NetworkTileProvider` never hits the
/// real internet during widget tests — it would otherwise block pumpAndSettle
/// for the full timeout window on every frame.
class _TileHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _NoNetHttpClient();
  }
}

class _NoNetHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) {
    throw const SocketException('Tile network disabled in tests.');
  }

  @override
  void close({bool force = false}) {
    // No-op so tile providers don't throw during teardown.
  }
}

Future<void> pumpMap(WidgetTester tester, List<Override> overrides) async {
  HttpOverrides.global = _TileHttpOverrides();
  addTearDown(() => HttpOverrides.global = null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: Scaffold(body: MapScreen())),
    ),
  );
  // Two frames: build + the microtask in initState that calls loadEnabled.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('toolbar renders every layer chip and the catalog default-on',
      (tester) async {
    await pumpMap(tester, [
      gisRepositoryProvider.overrideWithValue(TestGisRepo()),
      commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
    ]);

    for (final spec in kMapLayers) {
      expect(
        find.byKey(ValueKey('layer-chip-${spec.id}')),
        findsOneWidget,
        reason: 'missing chip for ${spec.id}',
      );
    }

    final segmentsChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('layer-chip-segments')),
    );
    expect(segmentsChip.selected, isTrue);

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('toggling a layer flips the chip', (tester) async {
    await pumpMap(tester, [
      gisRepositoryProvider.overrideWithValue(TestGisRepo()),
      commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
    ]);

    // `segments` is the leftmost chip — guaranteed visible in the default
    // 800×600 test viewport. It is `defaultOn: true`, so a tap unselects it.
    final segmentsChip = find.byKey(const ValueKey('layer-chip-segments'));
    expect(tester.widget<FilterChip>(segmentsChip).selected, isTrue);

    await tester.tap(segmentsChip);
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.widget<FilterChip>(segmentsChip).selected, isFalse);
  });

  testWidgets('layer load failure surfaces a Retry row', (tester) async {
    await pumpMap(tester, [
      gisRepositoryProvider.overrideWithValue(TestThrowingRepo()),
      commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
    ]);

    expect(
      find.byKey(const ValueKey('layer-retry-segments')),
      findsOneWidget,
    );
    expect(find.textContaining('Road status layer failed'), findsOneWidget);
  });

  testWidgets('cached empty result shows the "no features" row',
      (tester) async {
    await pumpMap(tester, [
      gisRepositoryProvider.overrideWithValue(TestEmptyRepo()),
      commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
    ]);

    expect(
      find.textContaining('Road status: no features in your scope'),
      findsOneWidget,
    );
  });

  testWidgets('valid coordinate search pins and resolves the locate',
      (tester) async {
    await pumpMap(tester, [
      gisRepositoryProvider.overrideWithValue(TestGisRepo()),
      commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
    ]);

    await tester.enterText(find.byType(TextField), '26.15, 91.80');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('AS · KAMRUP · OK'), findsOneWidget);
  });
}
