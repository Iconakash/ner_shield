import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/dashboard/dashboard_screen.dart';
import 'package:ner_shield/models/cached_result.dart';
import 'package:ner_shield/models/command_summary.dart';
import 'package:ner_shield/repositories/command_repository.dart';
import 'package:ner_shield/services/command_service.dart';
import 'package:ner_shield/shared/widgets/screen_states.dart';

/// Deterministic repository stub — no network, no fabricated server data
/// beyond the explicit fixture declared inside this test.
class _FixedSummaryRepository extends CommandRepository {
  _FixedSummaryRepository(this._result) : super(CommandService(Dio()));

  final CachedResult<CommandSummary> _result;

  @override
  Future<CachedResult<CommandSummary>> summary() async => _result;
}

class _ThrowingRepository extends CommandRepository {
  _ThrowingRepository() : super(CommandService(Dio()));

  @override
  Future<CachedResult<CommandSummary>> summary() async {
    throw const ParsingException('Command summary was malformed.');
  }
}

CachedResult<CommandSummary> _summary({
  bool fromCache = false,
  int criticalAlerts = 2,
  int highRiskRoads = 1,
  int activeShipments = 3,
  int criticalShipments = 0,
  int supplyRiskDistricts = 0,
  int predictedDisruptions = 4,
}) {
  return CachedResult(
    CommandSummary(
      criticalAlerts: criticalAlerts,
      highRiskRoads: highRiskRoads,
      activeShipments: activeShipments,
      criticalShipments: criticalShipments,
      supplyRiskDistricts: supplyRiskDistricts,
      predictedDisruptions: predictedDisruptions,
      generatedAt: '2026-08-31T09:00:00+00:00',
    ),
    fromCache: fromCache,
    cachedAt: fromCache ? DateTime(2026, 8, 31, 9) : null,
  );
}

Future<void> _pump(WidgetTester tester, List<Override> overrides) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
}

void main() {
  testWidgets('renders the frozen six KPI tiles from the live summary',
      (tester) async {
    await _pump(tester, [
      commandRepositoryProvider
          .overrideWithValue(_FixedSummaryRepository(_summary())),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Command overview'), findsOneWidget);
    // The backend's frozen tile descriptions, in its order.
    expect(find.text('Open CRITICAL alerts awaiting action'), findsOneWidget);
    expect(find.text('Road segments with latest risk HIGH/CRITICAL'),
        findsOneWidget);
    expect(find.text('Shipments routed or in transit'), findsOneWidget);
    expect(find.text('Active shipments carrying critical commodities'),
        findsOneWidget);
    expect(find.text('Districts with recent shortage probability >= 55'),
        findsOneWidget);
    expect(find.text('Districts currently flagged by the prediction engine'),
        findsOneWidget);
    // Counts render (never color alone — numbers + labels are asserted).
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('cached result shows the explicit offline banner and stale label',
      (tester) async {
    await _pump(tester, [
      commandRepositoryProvider
          .overrideWithValue(_FixedSummaryRepository(_summary(fromCache: true))),
    ]);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.byType(StaleLabel), findsOneWidget);
  });

  testWidgets('repository failure renders the error state with retry',
      (tester) async {
    await _pump(tester, [
      commandRepositoryProvider
          .overrideWithValue(_ThrowingRepository()),
    ]);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Command summary was malformed.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('all-zero summary still renders tiles plus the empty state',
      (tester) async {
    await _pump(tester, [
      commandRepositoryProvider.overrideWithValue(
        _FixedSummaryRepository(
          _summary(
            criticalAlerts: 0,
            highRiskRoads: 0,
            activeShipments: 0,
            predictedDisruptions: 0,
          ),
        ),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.text('Nothing needs your attention'),
      findsOneWidget,
    );
  });
}
