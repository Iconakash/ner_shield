import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/maps/map_controller.dart';

import 'phase8_map_fakes.dart';

void main() {
  group('MapController', () {
    test('starts every layer in the catalog with the catalog defaultOn', () {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      final state = c.read(mapControllerProvider);
      final ids = state.layers.keys.toSet();
      expect(ids, contains('segments'));
      expect(ids, contains('facilities'));
      expect(ids, contains('high_risk_roads'));
      expect(state.layers['segments']!.enabled, isTrue);
      expect(state.layers['weather']!.enabled, isFalse);
    });

    test('parseCoordinates accepts lat,lon / lat;lon / lat lon', () {
      expect(MapController.parseCoordinates('26.15, 91.80'),
          const LatLng(26.15, 91.80));
      expect(MapController.parseCoordinates('26.15;91.80'),
          const LatLng(26.15, 91.80));
      expect(MapController.parseCoordinates('  26.15   91.80  '),
          const LatLng(26.15, 91.80));
    });

    test('parseCoordinates rejects malformed input', () {
      expect(MapController.parseCoordinates(''), isNull);
      expect(MapController.parseCoordinates('hello'), isNull);
      expect(MapController.parseCoordinates('26.15'), isNull);
      expect(MapController.parseCoordinates('26.15, 91.80, 7'), isNull);
      expect(MapController.parseCoordinates('200, 0'), isNull);
      expect(MapController.parseCoordinates('0, 200'), isNull);
    });

    test('loadEnabled fills the default-on layers from the repo', () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(mapControllerProvider.notifier).loadEnabled();
      final segments = c.read(mapControllerProvider).layers['segments'];
      expect(segments, isNotNull);
      expect(segments!.data.hasValue, isTrue);
    });

    test('toggle off clears the layer; toggle on reloads it', () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      final notifier = c.read(mapControllerProvider.notifier);
      await notifier.loadEnabled();
      await notifier.toggle('facilities');
      var facilities = c.read(mapControllerProvider).layers['facilities']!;
      expect(facilities.enabled, isTrue);
      expect(facilities.data.hasValue, isTrue);
      await notifier.toggle('facilities');
      facilities = c.read(mapControllerProvider).layers['facilities']!;
      expect(facilities.enabled, isFalse);
    });

    test('layer load failure lands in the layer AsyncValue', () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestThrowingRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(mapControllerProvider.notifier).loadEnabled();
      final segments = c.read(mapControllerProvider).layers['segments'];
      expect(segments, isNotNull);
      expect(segments!.data.hasError, isTrue);
      expect(segments.data.error, isA<NetworkException>());
    });

    test('search pins the parsed coordinate and resolves the locate',
        () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(mapControllerProvider.notifier).search('26.15, 91.80');
      final state = c.read(mapControllerProvider);
      expect(state.locatePoint, isNotNull);
      expect(state.locate.valueOrNull, isNotNull);
      expect(state.locate.valueOrNull!.value.stateCode, 'AS');
      expect(state.locate.valueOrNull!.value.districtCode, 'KAMRUP');
    });

    test('bad search input produces a ValidationException in locate',
        () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(mapControllerProvider.notifier).search('not coords');
      final state = c.read(mapControllerProvider);
      expect(state.locate.hasError, isTrue);
      expect(state.locate.error, isA<ValidationException>());
      expect(state.locatePoint, isNull);
    });

    test('clearLocate drops both the pin and the resolved result', () async {
      final c = ProviderContainer(
        overrides: [
          gisRepositoryProvider.overrideWithValue(TestGisRepo()),
          commandRepositoryProvider.overrideWithValue(TestCommandRepo()),
        ],
      );
      addTearDown(c.dispose);
      final notifier = c.read(mapControllerProvider.notifier);
      await notifier.search('26.15, 91.80');
      expect(c.read(mapControllerProvider).locatePoint, isNotNull);
      notifier.clearLocate();
      expect(c.read(mapControllerProvider).locatePoint, isNull);
    });
  });
}
