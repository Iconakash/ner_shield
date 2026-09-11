import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/features/maps/feature_detail_sheet.dart';
import 'package:ner_shield/features/maps/map_controller.dart';
import 'package:ner_shield/models/geojson.dart';

import 'phase8_map_fakes.dart';

/// The bottom-sheet test pumps no map (no tile network needed).
void main() {
  testWidgets('showFeatureDetail renders title, status chip, and DEMO badge',
      (tester) async {
    final demoFeature = GeoJsonFeature(
      type: 'Feature',
      id: 'demo-1',
      geometry: {
        'type': 'Point',
        'coordinates': [91.74, 26.14],
      },
      properties: {
        'name': 'Demo Hub',
        'simulated': true,
        'severity': 'HIGH',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showFeatureDetail(
                  context,
                  layerLabel: 'Facilities',
                  feature: demoFeature,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Demo Hub'), findsOneWidget);
    expect(find.textContaining('DEMO / SIMULATED'), findsOneWidget);
    expect(find.text('Facilities'), findsOneWidget);
  });

  testWidgets('showFeatureDetail uses the road-status vocabulary for segments',
      (tester) async {
    final segFeature = GeoJsonFeature(
      type: 'Feature',
      id: 'seg-1',
      geometry: {
        'type': 'LineString',
        'coordinates': [
          [91.7, 26.1],
          [91.8, 26.2],
        ],
      },
      properties: {
        'name': 'NH-37 Kamrup stretch',
        'status': 'PARTIAL',
        'updated_at': '2026-08-31T09:00:00+00:00',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showFeatureDetail(
                context,
                layerLabel: 'Road status',
                feature: segFeature,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('NH-37 Kamrup stretch'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Road status'), findsOneWidget);
    // Date property is humanised, not raw.
    expect(find.textContaining('31 Aug 2026'), findsOneWidget);
  });

  test('controller: search → select → clear transitions are consistent',
      () async {
    final container = ProviderContainer(
      overrides: [
        gisRepositoryProvider.overrideWithValue(TestGisRepo()),
        commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(mapControllerProvider.notifier);

    await notifier.loadEnabled();
    final initial = container.read(mapControllerProvider);
    expect(initial.layers['segments']!.data.hasValue, isTrue);

    await notifier.search('26.15, 91.80');
    final searched = container.read(mapControllerProvider);
    expect(searched.locatePoint, isNotNull);
    expect(searched.locate.valueOrNull?.value.districtCode, 'KAMRUP');

    notifier.select(SelectedFeature(
      layerId: 'facilities',
      feature: testPointFeat('hub-1', 91.74, 26.14, 'Hub One'),
    ));
    expect(
      container.read(mapControllerProvider).selected?.layerId,
      'facilities',
    );

    notifier.select(null);
    expect(container.read(mapControllerProvider).selected, isNull);

    notifier.clearLocate();
    expect(container.read(mapControllerProvider).locatePoint, isNull);
  });
}
