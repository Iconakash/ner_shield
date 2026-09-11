// Phase 5 — offline risk-aware routing test matrix
// (master prompt §5.1–5.5). Covers the local engine (Dijkstra + mode
// profiles mirroring the server), the offline planner (output contract +
// stale/degraded labelling) and the persistent graph snapshot store.
//
// The tests run on pure Dart + an in-memory Drift database, so they
// execute in `flutter test` without a device/emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/routing/offline_route_engine.dart';
import 'package:ner_shield/core/routing/offline_route_graph_store.dart';
import 'package:ner_shield/core/routing/offline_route_planner.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';
import 'package:ner_shield/models/route_graph_snapshot.dart';

/// Three collinear junctions, 0.05° apart (wider than kSnapEpsDeg=0.03 so
/// they stay distinct). A—B and B—C are single 5 km segments each.
const List<RawGraphEdge> _lineRows = [
  RawGraphEdge(
    segmentId: 'SEG-A',
    roadCode: 'NH-01',
    seq: 1,
    x1: 93.00, y1: 25.00,
    x2: 93.05, y2: 25.00,
    lengthKm: 5.0, accessibility: 80.0, riskPct: 20.0,
  ),
  RawGraphEdge(
    segmentId: 'SEG-B',
    roadCode: 'NH-01',
    seq: 2,
    x1: 93.05, y1: 25.00,
    x2: 93.10, y2: 25.00,
    lengthKm: 5.0, accessibility: 60.0, riskPct: 80.0,
  ),
];

/// Two parallel A→B paths: a short high-risk edge and a long low-risk loop.
const List<RawGraphEdge> _parallelRows = [
  // fast but risky — straight line A->B
  RawGraphEdge(
    segmentId: 'FAST-1',
    roadCode: 'NH-01',
    seq: 1,
    x1: 93.00, y1: 25.00,
    x2: 93.05, y2: 25.00,
    lengthKm: 1.0, accessibility: 100.0, riskPct: 90.0,
  ),
  // safe loop A -> M -> B (two legs)
  RawGraphEdge(
    segmentId: 'SAFE-1',
    roadCode: 'SH-22',
    seq: 1,
    x1: 93.00, y1: 25.00,
    x2: 93.025, y2: 24.97,
    lengthKm: 3.0, accessibility: 100.0, riskPct: 5.0,
  ),
  RawGraphEdge(
    segmentId: 'SAFE-2',
    roadCode: 'SH-22',
    seq: 2,
    x1: 93.025, y1: 24.97,
    x2: 93.05, y2: 25.00,
    lengthKm: 3.0, accessibility: 100.0, riskPct: 5.0,
  ),
];

void main() {
  group('Phase 5 — mode profiles mirror the server', () {
    test('shortest is distance-only with zero risk aversion', () {
      final p = modeProfile('shortest');
      expect(p.distanceOnly, isTrue);
      expect(p.riskAversion, 0);
    });

    test('fastest ignores risk', () {
      final p = modeProfile('fastest');
      expect(p.distanceOnly, isFalse);
      expect(p.riskAversion, 0);
    });

    test('safest is fully risk-averse', () {
      final p = modeProfile('safest');
      expect(p.riskAversion, 1.0);
    });

    test('emergency has low aversion and a speed bonus', () {
      final p = modeProfile('emergency');
      expect(p.riskAversion, kEmergencyAversion);
      expect(p.speedMult, kEmergencySpeedBonus);
    });

    test('balanced derives aversion from priority', () {
      expect(modeProfile('balanced', 'CRITICAL').riskAversion,
          kPriorityAversion['CRITICAL']);
      expect(modeProfile('balanced', 'HIGH').riskAversion,
          kPriorityAversion['HIGH']);
      expect(modeProfile('balanced').riskAversion,
          kPriorityAversion['NORMAL']);
    });

    test('unknown modes are rejected, never silently degraded', () {
      expect(() => modeProfile('teleport'), throwsArgumentError);
    });
  });

  group('Phase 5 — risk labels and ETA formatting (server bands)', () {
    test('riskLabelFor maps 0..100 to the fixed bands', () {
      expect(riskLabelFor(90), 'CRITICAL');
      expect(riskLabelFor(85), 'CRITICAL');
      expect(riskLabelFor(70), 'HIGH');
      expect(riskLabelFor(50), 'ELEVATED');
      expect(riskLabelFor(20), 'GUARDED');
      expect(riskLabelFor(0), 'LOW');
    });

    test('fmtEta renders hhmm with zero padding', () {
      expect(fmtEta(2.5), '2h30');
      expect(fmtEta(0.5), '0h30');
      expect(fmtEta(1.05), '1h03');
    });

    test('haversineKm is sane for ~1° of latitude', () {
      final km = haversineKm((92.0, 25.0), (92.0, 26.0));
      expect(km, closeTo(111.2, 1.0));
    });
  });

  group('Phase 5 — graph build and junction merge', () {
    test('co-linear rows build three junctions and two edges', () {
      final built = buildOfflineGraph(_lineRows);
      expect(built.junctionCoords, hasLength(3));
      final route = built.graph.dijkstra(
        snapToJunction(built.junctionCoords, 93.0, 25.0)!,
        snapToJunction(built.junctionCoords, 93.10, 25.0)!,
        riskAversion: 0,
      );
      expect(route, isNotNull);
      expect(route!.segments.map((s) => s.segmentId), ['SEG-A', 'SEG-B']);
      expect(route.distanceKm, 10.0);
      expect(route.nodePath.first,
          snapToJunction(built.junctionCoords, 93.0, 25.0));
      expect(route.nodePath.last,
          snapToJunction(built.junctionCoords, 93.10, 25.0));
    });

    test('near endpoints merge; far endpoints stay separate', () {
      final merged = mergeEndpoints(const [
        (0, 0, 93.0, 25.0),
        (1, 0, 93.0 + 0.001, 25.0), // within 0.03° — merges with A
        (2, 0, 93.2, 25.0), // far away — separate junction
      ]);
      expect(merged.values.toSet(), hasLength(2));
    });

    test('self-loops are dropped for server parity', () {
      final built = buildOfflineGraph([
        RawGraphEdge(
          segmentId: 'LOOP',
          roadCode: 'R',
          seq: 1,
          x1: 93.0, y1: 25.0,
          x2: 93.0, y2: 25.0,
          lengthKm: 1, accessibility: 100, riskPct: 10,
        ),
      ]);
      // The self-loop edge must not enter the graph at all.
      expect(built.graph.isEmpty, isTrue);
    });

    test('snapToJunction picks the closest coordinate', () {
      final built = buildOfflineGraph(_lineRows);
      final j = snapToJunction(built.junctionCoords, 93.04, 25.002)!;
      expect(built.junctionCoords[j], (93.05, 25.0));
    });
  });

  group('Phase 5 — Dijkstra semantics', () {
    test('blocked segment makes a route unreachable (never silent)', () {
      final built = buildOfflineGraph(_lineRows);
      final src = snapToJunction(built.junctionCoords, 93.0, 25.0)!;
      final dst = snapToJunction(built.junctionCoords, 93.10, 25.0)!;
      final route =
          built.graph.dijkstra(src, dst, riskAversion: 0, blocked: {'SEG-A'});
      expect(route, isNull);
    });

    test('fastest mode prefers the fast high-risk edge', () {
      final built = buildOfflineGraph(_parallelRows);
      final route = built.graph.dijkstra(
        snapToJunction(built.junctionCoords, 93.0, 25.0)!,
        snapToJunction(built.junctionCoords, 93.05, 25.0)!,
        riskAversion: 0,
      );
      expect(route!.segments.single.segmentId, 'FAST-1');
      expect(route.riskPct, 90.0);
    });

    test('safest mode avoids the high-risk edge even when longer', () {
      final built = buildOfflineGraph(_parallelRows);
      final route = built.graph.dijkstra(
        snapToJunction(built.junctionCoords, 93.0, 25.0)!,
        snapToJunction(built.junctionCoords, 93.05, 25.0)!,
        riskAversion: 1.0,
      );
      expect(route!.segments.map((s) => s.segmentId), ['SAFE-1', 'SAFE-2']);
      expect(route.riskPct, lessThan(10));
    });

    test('disconnected components produce no route', () {
      final rows = <RawGraphEdge>[
        ..._lineRows,
        RawGraphEdge(
          segmentId: 'ISLAND',
          roadCode: 'R-9',
          seq: 9,
          x1: 96.0, y1: 28.0,
          x2: 96.05, y2: 28.0,
          lengthKm: 5, accessibility: 100, riskPct: 0,
        ),
      ];
      final built = buildOfflineGraph(rows);
      final src = snapToJunction(built.junctionCoords, 93.0, 25.0)!;
      final island = snapToJunction(built.junctionCoords, 96.025, 28.0)!;
      expect(built.graph.dijkstra(src, island, riskAversion: 0), isNull);
    });
  });

  group('Phase 5 — k distinct alternatives', () {
    test('returns distinct signatures up to k', () {
      final built = buildOfflineGraph(_lineRows);
      final routes = kDistinctRoutes(
        built.graph,
        snapToJunction(built.junctionCoords, 93.0, 25.0)!,
        snapToJunction(built.junctionCoords, 93.10, 25.0)!,
        k: 3,
        riskAversion: 0.5,
      );
      // One corridor only → exactly one distinct alternative.
      expect(routes, hasLength(1));
      expect(routes.single.segments, hasLength(2));
    });

    test('parallel corridors yield multiple alternatives', () {
      final built = buildOfflineGraph(_parallelRows);
      final routes = kDistinctRoutes(
        built.graph,
        snapToJunction(built.junctionCoords, 93.0, 25.0)!,
        snapToJunction(built.junctionCoords, 93.05, 25.0)!,
        k: 3,
        riskAversion: 1.0,
        // The safe loop wins by a wide margin at aversion 1.0, so the
        // default 1.6× penalty would never surface the fast alternative.
        // A stronger penalty (matching operational reroute pressure) does.
        penaltyFactor: 50,
      );
      expect(routes.length, greaterThanOrEqualTo(2));
      final signatures = routes
          .map((r) => r.segments.map((s) => s.segmentId).join('|'))
          .toSet();
      expect(signatures.length, routes.length);
      // Rank 1 is the safe loop; the penalised alternative uses FAST-1.
      expect(routes.first.segments.map((s) => s.segmentId),
          ['SAFE-1', 'SAFE-2']);
      expect(routes.last.segments.single.segmentId, 'FAST-1');
    });
  });

  group('Phase 5 — offline planner contract', () {
    test('produces a ranked plan with explicit offline/stale labelling', () {
      final result = planOffline(
        _lineRows,
        originLon: 93.0, originLat: 25.0,
        destLon: 93.10, destLat: 25.0,
        mode: 'balanced',
        snapshotAt: DateTime.now().toUtc(),
        stale: true,
        snapshotAge: const Duration(hours: 9),
      );
      expect(result.stale, isTrue);
      final route = result.plan.routes.single;
      expect(route.rank, 1);
      expect(route.segments, hasLength(2));
      expect(route.totalEtaMinutes, greaterThan(0));
      expect(route.narrative, contains('OFFLINE PLAN'));
      expect(route.narrative, contains('STALE'));
      expect(result.degradedNotes, isA<List<String>>());
    });

    test('empty graph raises a clear degraded-mode error', () {
      expect(
        () => planOffline(
          const [],
          originLon: 93.0, originLat: 25.0,
          destLon: 93.1, destLat: 25.0,
          snapshotAt: DateTime.now().toUtc(),
          stale: true,
        ),
        throwsA(isA<OfflinePlanException>()),
      );
    });

    test('origin/destination snapping to the same junction raises', () {
      // snapToJunction has no max-distance rejection (server parity), so an
      // arbitrary far-away point snaps to the nearest junction and plans
      // normally. The genuine degenerate case is two points on the same
      // junction — the planner must refuse rather than emit a fake route.
      expect(
        () => planOffline(
          _lineRows,
          originLon: 93.0, originLat: 25.0,
          destLon: 93.001, destLat: 25.0,
          snapshotAt: DateTime.now().toUtc(),
          stale: false,
        ),
        throwsA(isA<OfflinePlanException>()),
      );
    });

    test('emergency mode flags high-risk corridor explicitly', () {
      final result = planOffline(
        _lineRows,
        originLon: 93.0, originLat: 25.0,
        destLon: 93.10, destLat: 25.0,
        mode: 'emergency',
        snapshotAt: DateTime.now().toUtc(),
        stale: false,
      );
      final route = result.plan.routes.single;
      // SEG-B is 80% risk → HIGH, so high-risk warnings must be surfaced.
      expect(route.segments.any((s) => s['risk_pct'] >= 70), isTrue);
      expect(route.narrative, contains('high-risk'));
    });

    test('fresh (non-stale) snapshot is labelled as last synced', () {
      final result = planOffline(
        _lineRows,
        originLon: 93.0, originLat: 25.0,
        destLon: 93.10, destLat: 25.0,
        mode: 'fastest',
        snapshotAt: DateTime.now().toUtc(),
        stale: false,
      );
      expect(result.stale, isFalse);
      expect(result.plan.routes.single.narrative,
          contains('last synced snapshot'));
      expect(result.plan.routes.single.narrative, isNot(contains('STALE')));
    });
  });

  group('Phase 5 — persistent graph-snapshot store', () {
    late SyncQueueDatabase db;
    late OfflineRouteGraphStore store;

    setUp(() async {
      RouteGraphSnapshot snapshot() => RouteGraphSnapshot(
          fetchedAt: DateTime.now().toUtc(),
          openSegments: [
            RouteGraphSegment(
              segmentId: 'SEG-A', roadCode: 'NH-01', seq: 1,
              x1: 93.0, y1: 25.0, x2: 93.05, y2: 25.0,
              lengthKm: 5, accessibility: 80, riskPct: 20,
            ),
          ],
          closedSegments: [
            RouteGraphClosedSegment(
              segmentId: 'SEG-X', roadCode: 'NH-09', seq: 7,
              x1: 94.0, y1: 26.0, x2: 94.04, y2: 26.0,
            ),
          ]);

      db = SyncQueueDatabase.memory();
      store = OfflineRouteGraphStore(db);
      await store.save(snapshot());
    });

    tearDown(() async {
      await db.close();
    });

    test('load returns null before any snapshot was saved', () async {
      final empty = SyncQueueDatabase.memory();
      final freshStore = OfflineRouteGraphStore(empty);
      expect(await freshStore.load(), isNull);
      expect(await freshStore.lastFetchedAt(), isNull);
      await empty.close();
    });

    test('open rows + closed ids + provenance round-trip (restart)', () async {
      final reloaded = OfflineRouteGraphStore(db);
      final stored = await reloaded.load();
      expect(stored, isNotNull);
      expect(stored!.openRows.single.segmentId, 'SEG-A');
      expect(stored.closedSegmentIds, contains('SEG-X'));
      expect(stored.fetchedAt, isNotNull);
    });

    test('stale detection uses the 6 h default budget', () {
      final fresh = StoredGraphSnapshot(
        openRows: const [], closedSegmentIds: const [],
        fetchedAt: DateTime.now().toUtc(),
      );
      expect(fresh.isStale(), isFalse);

      final old = StoredGraphSnapshot(
        openRows: const [], closedSegmentIds: const [],
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 7)),
      );
      expect(old.isStale(), isTrue);
    });

    test('lastFetchedAt reflects the stored snapshot', () async {
      final at = await store.lastFetchedAt();
      expect(at, isNotNull);
      expect(DateTime.now().toUtc().difference(at!),
          lessThan(const Duration(minutes: 5)));
    });
  });
}