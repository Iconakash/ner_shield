// Phase 6 — OFFLINE risk prediction degradation test matrix
// (master prompt §6). All tests run against an in-memory Drift database so
// they execute in `flutter test` without a device/emulator.

import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/risk/offline_risk.dart';
import 'package:ner_shield/core/risk/offline_risk_store.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';
import 'package:ner_shield/models/risk_item.dart';
import 'package:ner_shield/repositories/risk_repository.dart';
import 'package:ner_shield/services/risk_service.dart';

RiskPrediction _prediction(String id, {double risk = 55.0, DateTime? computedAt}) {
  return RiskPrediction(
    segmentId: id,
    roadCode: 'NH-$id',
    districtCode: 'IN-MN-IW',
    riskCurrent: risk,
    risk6h: risk - 5,
    risk12h: risk - 10,
    risk24h: risk - 15,
    risk72h: risk - 20,
    overallLabel: risk >= 70 ? 'HIGH' : 'GUARDED',
    severity: risk >= 70 ? 'MAJOR' : 'MINOR',
    topFactors: const [
      <String, dynamic>{'feature': 'rainfall_mm_24h', 'contribution': 18.0},
    ],
    summarySentence: 'Elevated risk from rainfall',
    baseValue: 40,
    mode: 'HEURISTIC',
    modelName: 'ner-risk-baseline',
    modelVersion: 'v1',
    computedAt:
        (computedAt ?? DateTime.now().toUtc()).toIso8601String(),
  );
}

/// In-memory [RiskService] double — never touches the network.
class FakeRiskService implements RiskService {
  FakeRiskService({this.latestResult, this.latestException});

  List<RiskPrediction>? latestResult;
  AppException? latestException;
  int latestCalls = 0;

  @override
  Future<List<RiskPrediction>> latest({String? districtCode}) async {
    latestCalls += 1;
    if (latestException != null) throw latestException!;
    return latestResult ?? const [];
  }

  @override
  Future<RiskExplain> explain(String segmentId) async {
    throw const NetworkException('explain not needed');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 6 — freshness + confidence model', () {
    test('freshness bands: live ≤30m, recent ≤6h, stale beyond', () {
      expect(classifyRiskFreshness(const Duration(minutes: 10)),
          RiskFreshness.live);
      expect(classifyRiskFreshness(const Duration(hours: 2)),
          RiskFreshness.recent);
      expect(classifyRiskFreshness(const Duration(hours: 7)),
          RiskFreshness.stale);
    });

    test('confidence decays monotonically and never leaves 0.1..1.0', () {
      final ages = <Duration>[
        const Duration(minutes: 6),
        const Duration(minutes: 30),
        const Duration(hours: 1),
        const Duration(hours: 3),
        const Duration(hours: 6),
        const Duration(hours: 12),
        const Duration(hours: 24),
        const Duration(hours: 48),
        const Duration(hours: 100),
      ];
      var prev = double.infinity;
      for (final age in ages) {
        final c = riskConfidenceFor(age);
        expect(c, inInclusiveRange(0.1, 1.0));
        expect(c, lessThanOrEqualTo(prev));
        prev = c;
      }
      expect(riskConfidenceFor(const Duration(minutes: 1)), 1.0);
      expect(riskConfidenceFor(const Duration(hours: 6)).toStringAsFixed(2),
          '0.50');
    });

    test('stale snapshot is explicitly labelled, never presented fresh', () {
      final fetched = DateTime.now().toUtc().subtract(const Duration(hours: 9));
      final result = buildOfflineRiskResult(
        predictions: [_prediction('S1')],
        fetchedAt: fetched,
        computedAt: fetched.subtract(const Duration(minutes: 30)),
        now: DateTime.now().toUtc(),
      );
      expect(result.stale, isTrue);
      expect(result.featureFreshness, RiskFreshness.stale);
      expect(result.servedFromCache, isTrue);
      expect(result.degradedReasons.any((r) => r.contains('stale')), isTrue);
      expect(result.predictions.single.segmentId, 'S1');
    });

    test('fresh snapshot is not stale and carries full confidence', () {
      final fetched = DateTime.now().toUtc();
      final result = buildOfflineRiskResult(
        predictions: [_prediction('S1')],
        fetchedAt: fetched,
        computedAt: fetched,
        now: fetched.add(const Duration(minutes: 5)),
      );
      expect(result.stale, isFalse);
      expect(result.featureFreshness, RiskFreshness.live);
      expect(result.confidence, 1.0);
    });
  });

  group('Phase 6 — persistent risk snapshot store', () {
    late SyncQueueDatabase db;

    setUp(() async {
      db = SyncQueueDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('load reports null before any successful sync', () async {
      expect(await OfflineRiskStore(db).load(), isNull);
      expect(await OfflineRiskStore(db).lastFetchedAt(), isNull);
    });

    test('stale detection uses injected clock', () async {
      final fetchedAt = DateTime.now().toUtc();
      await OfflineRiskStore(db).save(
        [_prediction('S1')],
        fetchedAt: fetchedAt,
      );
      final aged = await OfflineRiskStore(db).load(
        now: fetchedAt.add(const Duration(hours: 8)),
      );
      expect(aged!.stale, isTrue);
      expect(aged.featureFreshness, RiskFreshness.stale);
      expect(aged.confidence, lessThan(0.5));

      final fresh = await OfflineRiskStore(db).load(
        now: fetchedAt.add(const Duration(minutes: 10)),
      );
      expect(fresh!.stale, isFalse);
    });

    test('clear wipes the snapshot (logout privacy hook)', () async {
      await OfflineRiskStore(db).save(
        [_prediction('S1')],
        fetchedAt: DateTime.now().toUtc(),
      );
      await OfflineRiskStore(db).clear();
      expect(await OfflineRiskStore(db).load(), isNull);
    });

    test('save → reopen (restart) → load round-trips server rows verbatim',
        () async {
      final fetchedAt = DateTime.now().toUtc();
      await OfflineRiskStore(db).save(
        [_prediction('S1', risk: 82), _prediction('S2', risk: 31)],
        districtCode: 'IN-MN-IW',
        fetchedAt: fetchedAt,
      );
      // App-restart simulation: a brand-new store over the same database.
      final reopened = await OfflineRiskStore(db).load(
        now: fetchedAt.add(const Duration(minutes: 2)),
      );
      expect(reopened, isNotNull);
      expect(reopened!.predictions, hasLength(2));
      final s1 = reopened.predictions.first;
      expect(s1.segmentId, 'S1');
      expect(s1.riskCurrent, 82);
      expect(s1.overallLabel, 'HIGH');
      expect(s1.topFactors?.single['feature'], 'rainfall_mm_24h');
      expect(reopened.stale, isFalse);
      expect(
        reopened.fetchedAt.difference(fetchedAt).inSeconds.abs() < 5,
        isTrue,
      );
    });
  });

  group('Phase 6 — repository offline fallback', () {
    test('successful fetch writes through to the persistent snapshot', () async {
      final db = SyncQueueDatabase.memory();
      addTearDown(() => db.close());
      final fake = FakeRiskService(latestResult: [_prediction('S1')]);
      final repo = RiskRepository(
        fake,
        offlineStore: OfflineRiskStore(db),
      );
      final live = await repo.latest();
      expect(live.fromCache, isFalse);
      expect(live.value, hasLength(1));
      // New repository over the same db = app-restart simulation.
      final reopened = RiskRepository(
        FakeRiskService(latestException: const NetworkException('offline')),
        offlineStore: OfflineRiskStore(db),
      );
      final fallback = await reopened.latest();
      expect(fallback.fromCache, isTrue);
      expect(fallback.value.single.segmentId, 'S1');
      expect(fake.latestCalls, 1);
    });

    test('network failure + persisted snapshot = labelled cached result',
        () async {
      final db = SyncQueueDatabase.memory();
      addTearDown(() => db.close());
      final fetched = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      await OfflineRiskStore(db).save(
        // The server computed the snapshot at/before the fetch instant —
        // a 2h-old device snapshot carries a ≥2h-old feature run.
        [_prediction('S1', risk: 71, computedAt: fetched)],
        fetchedAt: fetched,
      );
      final repo = RiskRepository(
        FakeRiskService(latestException: const NetworkException('no signal')),
        offlineStore: OfflineRiskStore(db),
      );
      final result = await repo.latest();
      expect(result.fromCache, isTrue);
      expect(result.value.single.overallLabel, 'HIGH');
      final offline = await repo.offlineSnapshot();
      expect(offline, isNotNull);
      expect(offline!.stale, isFalse); // 2h < 6h budget
      expect(offline.featureFreshness, RiskFreshness.recent);
    });

    test('network failure without a snapshot rethrows (no fabricated risk)',
        () async {
      final db = SyncQueueDatabase.memory();
      addTearDown(() => db.close());
      final repo = RiskRepository(
        FakeRiskService(latestException: const NetworkException('no signal')),
        offlineStore: OfflineRiskStore(db),
      );
      expect(() => repo.latest(), throwsA(isA<NetworkException>()));
      expect(await repo.offlineSnapshot(), isNull);
    });

    test('validation/5xx failures propagate — stale data never masks real '
        'errors', () async {
      final db = SyncQueueDatabase.memory();
      addTearDown(() => db.close());
      await OfflineRiskStore(db).save(
        [_prediction('S1')],
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
      );
      final repo = RiskRepository(
        FakeRiskService(
            latestException: const ValidationException('bad district')),
        offlineStore: OfflineRiskStore(db),
      );
      expect(() => repo.latest(), throwsA(isA<ValidationException>()));
    });
  });
}