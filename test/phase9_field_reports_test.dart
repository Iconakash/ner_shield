import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/sync/sync_queue.dart';
import 'package:ner_shield/features/incidents/report_wizard_controller.dart';
import 'package:ner_shield/models/field_report.dart';
import 'package:ner_shield/models/sync_queue_entry.dart';
import 'package:ner_shield/repositories/field_reports_repository.dart';
import 'package:ner_shield/services/field_reports_service.dart';

/// Phase 9 gate (master prompt §54, tests T7-T9): field-report models, sync
/// queue lifecycle, offline-first submit paths, and the wizard controller.
void main() {
  group('T7 — FieldReport model (verified /field/reports row)', () {
    test('parses server row with optional fields', () {
      final r = FieldReport.fromJson(const {
        'id': 'r1',
        'code': 'FR-0001',
        'incident_type': 'LANDSLIDE',
        'severity': 'HIGH',
        'status': 'UNDER_REVIEW',
        'description': 'Slide blocking lane two',
        'state_code': 'ASSAM',
        'district_code': 'KAMRUP',
        'lon': 91.7,
        'lat': 26.1,
        'confidence': 0.82,
      });
      expect(r.id, 'r1');
      expect(r.displayTitle, 'LANDSLIDE');
      expect(r.isOpen, isTrue);
      expect(r.isRejected, isFalse);
    });

    test('open/rejected status helpers', () {
      FieldReport withStatus(String status) =>
          FieldReport(id: 'x', incidentType: 'FLOOD', status: status);
      expect(withStatus('RECEIVED').isOpen, isTrue);
      expect(withStatus('IN_ACTION').isOpen, isTrue);
      expect(withStatus('RESOLVED').isOpen, isFalse);
      expect(withStatus('REJECTED').isRejected, isTrue);
    });

    test('NER coordinate bounds are inclusive at the edges', () {
      expect(FieldReport.withinBounds(lon: 80, lat: 21), isTrue);
      expect(FieldReport.withinBounds(lon: 98, lat: 29.5), isTrue);
      expect(FieldReport.withinBounds(lon: 79.9, lat: 26), isFalse);
      expect(FieldReport.withinBounds(lon: 98.1, lat: 26), isFalse);
      expect(FieldReport.withinBounds(lon: 91, lat: 20.9), isFalse);
      expect(FieldReport.withinBounds(lon: 91, lat: 29.6), isFalse);
    });

    test('draft completeness gates submission fields', () {
      final d = FieldReportsRepository.emptyDraft();
      expect(d.isComplete, isFalse);
      final full = d.copyWith(
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91.7,
        lat: 26.1,
      );
      expect(full.isComplete, isTrue);
    });
  });

  group('T8 — sync queue lifecycle', () {
    test('isFlushable only for retryable statuses', () {
      SyncQueueEntry withStatus(SyncQueueStatus s) => SyncQueueEntry(
        clientOpId: 'op',
        opType: 'FIELD_REPORT',
        payload: const {},
        status: s,
      );
      expect(withStatus(SyncQueueStatus.pending).isFlushable, isTrue);
      expect(withStatus(SyncQueueStatus.failed).isFlushable, isTrue);
      expect(withStatus(SyncQueueStatus.offline).isFlushable, isFalse);
      expect(withStatus(SyncQueueStatus.synced).isFlushable, isFalse);
    });

    test('enqueue / markStatus / remove lifecycle with history', () async {
      final queue = SyncQueue();
      const entry = SyncQueueEntry(
        clientOpId: 'op-1',
        opType: 'FIELD_REPORT',
        payload: {'incident_type': 'FLOOD'},
        status: SyncQueueStatus.offline,
      );
      await queue.enqueue(entry);
      expect(queue.entries, hasLength(1));
      expect(queue.pendingCount, 1);

      await queue.markStatus(
        clientOpId: 'op-1',
        status: SyncQueueStatus.pending,
      );
      expect(queue.entries.single.attempts, 1);
      expect(queue.history.single.outcome, 'pending');

      await queue.markStatus(
        clientOpId: 'op-1',
        status: SyncQueueStatus.synced,
        resourceId: 'r-9',
      );
      expect(queue.entries.single.isSynced, isTrue);
      expect(queue.entries.single.resourceId, 'r-9');
      expect(queue.pendingCount, 0);

      await queue.remove('op-1');
      expect(queue.entries, isEmpty);
    });

    test(
      'flushable honours op type allow-list, batch size and OFFLINE',
      () async {
        final queue = SyncQueue();
        Future<void> add(String id, String type) => queue.enqueue(
          SyncQueueEntry(
            clientOpId: id,
            opType: type,
            payload: const {},
            status: SyncQueueStatus.pending,
          ),
        );
        await add('a', 'FIELD_REPORT');
        await add('b', 'FIELD_REPORT');
        await add('c', 'MEDIA_UPLOAD');

        final mediaFlush = queue.flushable(
          connectivityClass: 'LIMITED',
          allowedTypes: const {'FIELD_REPORT', 'MEDIA_UPLOAD'},
          maxOps: 10,
          allowMedia: true,
        );
        expect(
          mediaFlush.map((e) => e.clientOpId),
          containsAll(['a', 'b', 'c']),
        );

        final noMedia = queue.flushable(
          connectivityClass: 'LIMITED',
          allowedTypes: const {'FIELD_REPORT'},
          maxOps: 10,
          allowMedia: false,
        );
        expect(noMedia.map((e) => e.clientOpId), ['a', 'b']);

        final capped = queue.flushable(
          connectivityClass: 'FULL',
          allowedTypes: const {'FIELD_REPORT', 'MEDIA_UPLOAD'},
          maxOps: 2,
          allowMedia: true,
        );
        expect(capped, hasLength(2));

        expect(
          queue.flushable(
            connectivityClass: 'OFFLINE',
            allowedTypes: const {'FIELD_REPORT'},
            maxOps: 10,
            allowMedia: true,
          ),
          isEmpty,
        );
      },
    );
  });

  group('T9 — repository submit (online vs offline vs validation)', () {
    late FieldReport serverReport;

    setUp(() {
      serverReport = FieldReport(
        id: 'srv-1',
        code: 'FR-0042',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        status: 'RECEIVED',
      );
    });

    test('online path returns SubmitLive', () async {
      final repo = FieldReportsRepository(
        _FakeFieldReportsService(() {})..stubbedReport = serverReport,
      );
      final result = await repo.submit(_completeDraft());
      expect(result, isA<SubmitLive>());
      final live = result as SubmitLive;
      expect(live.report.code, 'FR-0042');
    });

    test('offline path queues the draft, never fakes server success', () async {
      final repo = FieldReportsRepository(
        _FakeFieldReportsService(() => throw const NetworkException('offline')),
      );
      final result = await repo.submit(
        _completeDraft(mediaPaths: const ['/tmp/pic.jpg']),
      );
      expect(result, isA<SubmitQueued>());
      final entry = (result as SubmitQueued).entry;
      expect(entry.status, SyncQueueStatus.offline);
      expect(entry.opType, 'FIELD_REPORT');
      expect(entry.payload['incident_type'], 'FLOOD');
      expect(entry.payload['severity'], 'CRITICAL');
      expect(entry.payload['lon'], 91.7);
      expect(entry.payload['lat'], 26.1);
      expect(entry.payload['media_local_paths'], ['/tmp/pic.jpg']);
    });

    test('server validation refusal is queued as retryable pending', () async {
      final repo = FieldReportsRepository(
        _FakeFieldReportsService(
          () => throw const ValidationException('severity out of range'),
        ),
      );
      final result = await repo.submit(_completeDraft());
      expect(result, isA<SubmitQueued>());
      final entry = (result as SubmitQueued).entry;
      expect(entry.status, SyncQueueStatus.pending);
      expect(entry.lastError, 'severity out of range');
    });
  });

  group('T9 — wizard controller flow', () {
    ProviderContainer containerWith(_FakeFieldReportsService svc) {
      final container = ProviderContainer(
        overrides: [fieldReportsServiceProvider.overrideWithValue(svc)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('canAdvance gates each step until its field is set', () {
      final container = containerWith(_FakeFieldReportsService(() {}));
      final c = container.read(reportWizardProvider.notifier);
      expect(c.canAdvance, isFalse);
      c.setIncidentType('FLOOD');
      expect(c.canAdvance, isTrue);
      c.next();
      expect(c.canAdvance, isFalse);
      c.setSeverity('HIGH');
      expect(c.canAdvance, isTrue);
      c.next();
      // Location: not set yet.
      expect(c.canAdvance, isFalse);
    });

    test('out-of-bounds coordinates are refused with a surfaced reason', () {
      final container = containerWith(_FakeFieldReportsService(() {}));
      final c = container.read(reportWizardProvider.notifier);
      c.setIncidentType('FLOOD');
      c.next();
      c.setSeverity('HIGH');
      c.next();
      c.setLocation(lon: 120, lat: 26);
      final state = container.read(reportWizardProvider);
      expect(state.lastError, isNotNull);
      expect(state.draft.lon, isNull);
    });

    test('live submit: complete draft reaches the server result', () async {
      final svc = _FakeFieldReportsService(() {})
        ..stubbedReport = FieldReport(
          id: 'srv-2',
          code: 'FR-0077',
          incidentType: 'FLOOD',
          severity: 'HIGH',
        );
      final container = containerWith(svc);
      final c = container.read(reportWizardProvider.notifier);
      c.setIncidentType('FLOOD');
      c.next();
      c.setSeverity('HIGH');
      c.next();
      c.setLocation(lon: 91.7, lat: 26.1);
      c.next();
      c.setDescription('Water over causeway');
      c.next();
      expect(c.canAdvance, isTrue);
      await c.submit();
      final state = container.read(reportWizardProvider);
      expect(state.lastError, isNull);
      expect(state.lastResult, isA<SubmitLive>());
      expect(svc.createCalls, 1);
    });

    test('offline submit enqueues exactly one FIELD_REPORT op', () async {
      final container = containerWith(
        _FakeFieldReportsService(
          () => throw const NetworkException('airplane mode'),
        ),
      );
      final c = container.read(reportWizardProvider.notifier);
      c.setIncidentType('LANDSLIDE');
      c.next();
      c.setSeverity('CRITICAL');
      c.next();
      c.setLocation(lon: 92, lat: 25);
      c.next();
      c.next(); // description optional
      await c.submit();
      final state = container.read(reportWizardProvider);
      expect(state.lastResult, isA<SubmitQueued>());
      final queue = container.read(syncQueueProvider);
      expect(queue.entries, hasLength(1));
      expect(queue.entries.single.opType, 'FIELD_REPORT');
    });

    test('submit without required fields sets a readable error', () async {
      final container = containerWith(_FakeFieldReportsService(() {}));
      final c = container.read(reportWizardProvider.notifier);
      await c.submit();
      expect(container.read(reportWizardProvider).lastError, isNotNull);
    });
  });
}

FieldReportDraft _completeDraft({List<String> mediaPaths = const []}) =>
    FieldReportsRepository.emptyDraft().copyWith(
      incidentType: 'FLOOD',
      severity: 'CRITICAL',
      lon: 91.7,
      lat: 26.1,
      mediaPaths: mediaPaths,
    );

/// Deterministic fake standing in for the Dio-backed service.
class _FakeFieldReportsService extends FieldReportsService {
  _FakeFieldReportsService(this.behave) : super(Dio());

  final void Function() behave;
  FieldReport? stubbedReport;
  int createCalls = 0;

  @override
  Future<FieldReport> create({
    required String incidentType,
    required String severity,
    required double lon,
    required double lat,
    String? description,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? roadCode,
    String? locationName,
    String? source,
  }) async {
    createCalls++;
    behave();
    return stubbedReport ??
        FieldReport(id: 'generated', incidentType: incidentType);
  }
}
