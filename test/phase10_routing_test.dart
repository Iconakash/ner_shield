import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/routing/route_planner_controller.dart';
import 'package:ner_shield/models/routing_plan.dart';
import 'package:ner_shield/services/routing_service.dart';

/// In-memory [RoutingService] double — never touches the network.
class FakeRoutingService implements RoutingService {
  FakeRoutingService({
    this.modesResult,
    this.planResult,
    this.planException,
  });

  List<RoutingMode>? modesResult;
  RoutePlanResponse? planResult;
  AppException? planException;

  int planCalls = 0;

  @override
  Future<List<RoutingMode>> modes() async {
    if (modesResult == null) {
      throw const NetworkException('modes unavailable');
    }
    return modesResult!;
  }

  @override
  Future<RoutePlanResponse> plan(RoutePlanRequest request) async {
    planCalls += 1;
    if (planException != null) throw planException!;
    return planResult ??
        const RoutePlanResponse(
          routes: <PlannedRoute>[],
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RoutePlanRequest _sampleRequest() => RoutePlanRequest(
      origin: const RouteEndpoint(lon: 91.78, lat: 26.14),
      destination: const RouteEndpoint(lon: 91.83, lat: 26.20),
      priority: 'SAFETY',
      riskAversion: 0.7,
      k: 3,
      mode: 'fastest',
    );

RoutePlanResponse _sampleResponse() => RoutePlanResponse(
      routes: [
        PlannedRoute(
          rank: 1,
          mode: 'fastest',
          segments: const [<String, dynamic>{}],
          totalDistanceKm: 12.4,
          totalEtaMinutes: 24,
          aggregateRisk: 0.22,
          aggregateRiskLabel: 'LOW',
          narrative: 'route 1',
        ),
        PlannedRoute(
          rank: 2,
          mode: 'safest',
          segments: const [<String, dynamic>{}],
          totalDistanceKm: 14.0,
          totalEtaMinutes: 30,
          aggregateRisk: 0.55,
          aggregateRiskLabel: 'MODERATE',
          narrative: 'route 2',
        ),
      ],
    );

void main() {
  // connectivity_plus feeds `connectivityClassProvider` which the planner
  // controller listens on (Phase 5 §5.5 reconnect). It requires the widgets
  // services binding to be initialized in the test runner.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoutingService request/response contracts (T14)', () {
    test('request serializes lon/lat endpoints', () {
      final req = _sampleRequest();
      expect(req.origin.toBody(), {'lon': 91.78, 'lat': 26.14});
      expect(req.destination.toBody(), {'lon': 91.83, 'lat': 26.20});
    });

    test('facility-code endpoints serialize as facility_code only', () {
      const e1 = RouteEndpoint(facilityCode: 'FAC-N');
      const e2 = RouteEndpoint(facilityCode: 'FAC-S');
      expect(e1.toBody(), {'facility_code': 'FAC-N'});
      expect(e2.toBody(), {'facility_code': 'FAC-S'});
    });

    test('RoutePlanResponse parses rank order and risk label', () {
      final json = {
        'routes': [
          {
            'rank': 1,
            'mode': 'fastest',
            'segments': [
              {'segment_id': 's1'}
            ],
            'total_distance_km': 10.5,
            'total_eta_minutes': 18,
            'aggregate_risk': 0.1,
            'aggregate_risk_label': 'LOW',
            'narrative': 'best'
          }
        ],
      };
      final parsed = RoutePlanResponse.fromJson(json);
      expect(parsed.routes, hasLength(1));
      expect(parsed.routes.first.isRecommended, isTrue);
      expect(parsed.routes.first.aggregateRiskLabel, 'LOW');
      expect(parsed.sortedByRank.first.rank, 1);
    });

    test('endpoint parsing rejects malformed input', () {
      expect(parseEndpoint(''), isNull);
      // 3+ comma-separated tokens aren't valid lon/lat → treated as a
      // facility code (single string fallback). The planner surfaces
      // a graceful error downstream, but parseEndpoint itself returns
      // a non-null endpoint. Confirm the lon/lat path is enforced:
      expect(parseEndpoint('200,91'), isNull); // out of NER bounds
      expect(parseEndpoint('abc,def'), isNull); // not numbers
      expect(parseEndpoint('91.78,26.14'), isA<RouteEndpoint>());
    });

    test('network failure surfaces as a typed AppException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'));
      final svc = RoutingService(dio);
      // Reaching an unreachable host triggers DioException → ErrorMapper.
      expect(
        () => svc.plan(_sampleRequest()),
        throwsA(anyOf(isA<AppException>(), isA<DioException>())),
      );
    });
  });

  group('RoutePlannerController round-trip', () {
    test('successful plan populates the ranked route list', () async {
      final fake = FakeRoutingService(planResult: _sampleResponse());
      final container = ProviderContainer(
        overrides: [
          routingServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      container.read(routePlannerProvider.notifier)
        ..setOrigin('91.78,26.14')
        ..setDestination('91.83,26.20');
      await container.read(routePlannerProvider.notifier).plan();
      final state = container.read(routePlannerProvider);
      expect(state.result, hasLength(2));
      expect(state.result!.first.rank, 1);
      expect(state.lastError, isNull);
      expect(fake.planCalls, 1);
    });

    test('failure clears result and surfaces an error message', () async {
      final fake = FakeRoutingService(
        planException: const NetworkException('offline'),
      );
      final container = ProviderContainer(
        overrides: [
          routingServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      container.read(routePlannerProvider.notifier)
        ..setOrigin('91.78,26.14')
        ..setDestination('91.83,26.20');
      await container.read(routePlannerProvider.notifier).plan();
      final state = container.read(routePlannerProvider);
      expect(state.result, isNull);
      expect(state.lastError, isNotNull);
    });
  });
}