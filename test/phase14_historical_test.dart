import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/historical/historical_controller.dart';
import 'package:ner_shield/models/historical_event.dart';
import 'package:ner_shield/services/historical_service.dart';

class FakeHistoricalService implements HistoricalService {
  FakeHistoricalService({
    this.eventsResult,
    this.detailResult,
    this.failOn = const <String>{},
  });
  List<HistoricalEvent>? eventsResult;
  HistoricalEvent? detailResult;
  Set<String> failOn;

  @override
  Future<List<HistoricalEvent>> events() async {
    if (failOn.contains('events')) {
      throw const NetworkException('historical unavailable');
    }
    return eventsResult ?? const <HistoricalEvent>[];
  }

  @override
  Future<HistoricalEvent> eventDetail(String eventId) async {
    if (failOn.contains('detail')) {
      throw const NetworkException('detail unavailable');
    }
    return detailResult ??
        HistoricalEvent(id: eventId, title: 'event $eventId');
  }

  @override
  Future<HistoricalValidationRun> latestValidation(String eventId) async {
    return HistoricalValidationRun(
      id: 'r-1',
      eventId: eventId,
      modelName: 'baseline_v1',
      modelVersion: '1.0',
      datasetVersion: 'ds-1',
      metrics: <String, dynamic>{'accuracy': 0.91, 'f1': 0.88},
    );
  }

  @override
  Future<HistoricalValidationRun> runValidation(String eventId) async {
    return HistoricalValidationRun(id: 'r-2', eventId: eventId);
  }
}

List<HistoricalEvent> _sampleEvents() => const <HistoricalEvent>[
      HistoricalEvent(
        id: 'ev-1',
        title: 'Manipur flood 2023',
        description: 'historical',
        eventType: 'FLOOD',
        dataQuality: 'MEASURED',
        datasetVersion: 'ds-1',
      ),
      HistoricalEvent(
        id: 'ev-2',
        title: 'Simulated scenario A',
        description: 'replay',
        eventType: 'SIMULATED',
        dataQuality: 'SIMULATED',
      ),
    ];

void main() {
  group('Historical model', () {
    test('isMeasured only true for MEASURED data quality', () {
      const measured = HistoricalEvent(id: '1', dataQuality: 'MEASURED');
      const sample = HistoricalEvent(id: '2', dataQuality: 'SAMPLE');
      const none = HistoricalEvent(id: '3');
      expect(measured.isMeasured, isTrue);
      expect(sample.isMeasured, isFalse);
      expect(none.isMeasured, isFalse);
    });
  });

  group('Historical service + repository', () {
    test('events parses the payload', () async {
      final fake = FakeHistoricalService(eventsResult: _sampleEvents());
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result = await container.read(historicalRepositoryProvider).events();
      expect(result.value, hasLength(2));
      expect(result.value.first.isMeasured, isTrue);
      expect(result.value.last.isMeasured, isFalse);
    });

    test('events failure surfaces AppException', () async {
      final fake = FakeHistoricalService(failOn: {'events'});
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      expect(
        () => container.read(historicalRepositoryProvider).events(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('eventDetail returns one event with optional latest run', () async {
      final fake = FakeHistoricalService(
        detailResult: HistoricalEvent(
          id: 'ev-1',
          title: 'Manipur flood',
          dataQuality: 'MEASURED',
          latestRun: <String, dynamic>{'accuracy': 0.91},
        ),
      );
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result = await container.read(historicalRepositoryProvider).eventDetail('ev-1');
      expect(result.value.id, 'ev-1');
      expect(result.value.latestRun, isNotNull);
    });

    test('latestValidation returns the latest run with metrics', () async {
      final fake = FakeHistoricalService();
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result = await container.read(historicalRepositoryProvider).latestValidation('ev-1');
      expect(result.value.modelName, 'baseline_v1');
      expect(result.value.metrics!['accuracy'], 0.91);
    });

    test('runValidation forwards to the service', () async {
      final fake = FakeHistoricalService();
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result = await container.read(historicalRepositoryProvider).runValidation('ev-1');
      expect(result.eventId, 'ev-1');
    });
  });

  group('HistoricalEventsController', () {
    test('build exposes initial data, refresh re-fetches', () async {
      final fake = FakeHistoricalService(eventsResult: _sampleEvents());
      final container = ProviderContainer(
        overrides: [historicalServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      await container.read(historicalEventsProvider.future);
      expect(container.read(historicalEventsProvider).value?.value, hasLength(2));
      await container.read(historicalEventsProvider.notifier).refresh();
      expect(container.read(historicalEventsProvider).value?.value, hasLength(2));
    });
  });
}
