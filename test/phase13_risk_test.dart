import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/predictions/risk_controller.dart';
import 'package:ner_shield/models/risk_item.dart';
import 'package:ner_shield/services/risk_service.dart';

class FakeRiskService implements RiskService {
  FakeRiskService({
    this.latestResult,
    this.explainResult,
    this.failOn = const <String>{},
  });
  List<RiskPrediction>? latestResult;
  RiskExplain? explainResult;
  Set<String> failOn;
  int latestCalls = 0;
  int explainCalls = 0;
  String? lastDistrict;
  String? lastSegment;

  @override
  Future<List<RiskPrediction>> latest({String? districtCode}) async {
    latestCalls += 1;
    lastDistrict = districtCode;
    if (failOn.contains('latest')) {
      throw const NetworkException('risk unavailable');
    }
    return latestResult ?? const <RiskPrediction>[];
  }

  @override
  Future<RiskExplain> explain(String segmentId) async {
    explainCalls += 1;
    lastSegment = segmentId;
    if (failOn.contains('explain')) {
      throw const NetworkException('explain unavailable');
    }
    return explainResult ??
        RiskExplain(segmentId: segmentId, factors: const <RiskFactor>[]);
  }
}

List<RiskPrediction> _sampleLatest() => const <RiskPrediction>[
      RiskPrediction(
        segmentId: 'seg-A',
        riskCurrent: 0.7,
        risk24h: 0.85,
        overallLabel: 'CRITICAL',
        severity: 'HIGH',
      ),
      RiskPrediction(
        segmentId: 'seg-B',
        riskCurrent: 0.2,
        overallLabel: 'LOW',
      ),
    ];

void main() {
  group('Risk service + repository', () {
    test('latest parses the prediction payload', () async {
      final fake = FakeRiskService(latestResult: _sampleLatest());
      final container = ProviderContainer(overrides: [riskServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final result = await container.read(riskRepositoryProvider).latest();
      expect(result.value, hasLength(2));
      expect(result.value.first.isActionable, isTrue);
      expect(result.value.last.isActionable, isFalse);
    });

    test('latest with districtCode forwards the filter', () async {
      final fake = FakeRiskService(latestResult: _sampleLatest());
      final container = ProviderContainer(overrides: [riskServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      await container.read(riskRepositoryProvider).latest(districtCode: 'AS-01');
      expect(fake.lastDistrict, 'AS-01');
    });

    test('latest failure surfaces AppException', () async {
      final fake = FakeRiskService(failOn: {'latest'});
      final container = ProviderContainer(overrides: [riskServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      expect(
        () => container.read(riskRepositoryProvider).latest(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('explain returns WHY card for the requested segment', () async {
      final fake = FakeRiskService(
        explainResult: RiskExplain(
          segmentId: 'seg-A',
          baseValue: 0.4,
          factors: const <RiskFactor>[
            RiskFactor(feature: 'rainfall_24h', contribution: 0.6, label: 'Heavy rain'),
          ],
          narrative: 'Predicted risk driven by rainfall on NH-15',
        ),
      );
      final container = ProviderContainer(overrides: [riskServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final result = await container.read(riskRepositoryProvider).explain('seg-A');
      expect(result.value.segmentId, 'seg-A');
      expect(result.value.factors, hasLength(1));
      expect(result.value.factors!.first.feature, 'rainfall_24h');
      expect(result.value.narrative, contains('rainfall'));
    });
  });

  group('RiskController', () {
    test('refresh exposes loading then data', () async {
      final fake = FakeRiskService(latestResult: _sampleLatest());
      final container = ProviderContainer(overrides: [riskServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      await container.read(riskLatestProvider.future);
      expect(container.read(riskLatestProvider).value?.value, hasLength(2));
      await container.read(riskLatestProvider.notifier).refresh();
      expect(container.read(riskLatestProvider).value?.value, hasLength(2));
      expect(fake.latestCalls, 1);
    });
  });
}
