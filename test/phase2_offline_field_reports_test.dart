// Phase 2 - Offline field reports (master prompt sec 2.3 + 2.4 recovery
// matrix). All tests run against an in-memory Drift database so they
// execute in `flutter test` without device/emulator.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/drafts/draft_repository.dart';
import 'package:ner_shield/core/drafts/media_queue.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/sync/persistent_sync_queue_storage.dart';
import 'package:ner_shield/core/sync/sync_queue.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';
import 'package:ner_shield/core/validation/offline_draft_validator.dart';
import 'package:ner_shield/models/field_report.dart';
import 'package:ner_shield/models/sync_queue_entry.dart';
import 'package:ner_shield/repositories/field_reports_repository.dart';
import 'package:ner_shield/services/field_reports_service.dart';

SyncQueueEntry _parentOp(FieldReportDraft d, String clientOpId) {
  return SyncQueueEntry(
    clientOpId: clientOpId,
    opType: 'FIELD_REPORT',
    entityType: 'FIELD_REPORT',
    status: SyncQueueStatus.pending,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    payload: {
      'incident_type': d.incidentType,
      'severity': d.severity,
      'lon': d.lon,
      'lat': d.lat,
    },
  );
}

SyncQueueEntry _mediaOp(DraftMediaRef ref, String parentId) {
  return SyncQueueEntry(
    clientOpId: ref.clientRefId,
    opType: 'MEDIA_UPLOAD',
    entityType: 'MEDIA',
    status: SyncQueueStatus.pending,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    dependencyClientOpId: parentId,
    payload: {
      'local_path': ref.localPath,
      if (ref.contentType != null) 'content_type': ref.contentType,
    },
  );
}

void main() {
  group('Phase 2 - OfflineDraftValidator', () {
    test('null incident type returns readable error', () {
      final draft = FieldReportDraft(clientDraftId: 'd1');
      expect(const OfflineDraftValidator().validate(draft),
          'Choose an incident type.');
    });

    test('out-of-bounds coordinates returns readable reason', () {
      final draft = FieldReportDraft(
        clientDraftId: 'd2',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 60,
        lat: 10,
      );
      expect(const OfflineDraftValidator().validate(draft),
          contains('outside the NER region'));
    });

    test('media with empty path returns error', () {
      final draft = FieldReportDraft(
        clientDraftId: 'd3',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
        mediaRefs: [
          DraftMediaRef(clientRefId: 'm1', localPath: ''),
        ],
      );
      expect(const OfflineDraftValidator().validate(draft),
          contains('media is missing its local path'));
    });

    test('complete draft returns null', () {
      final draft = FieldReportDraft(
        clientDraftId: 'd4',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
      );
      expect(const OfflineDraftValidator().validate(draft), isNull);
    });
  });

  group('Phase 2 - dependency-aware flushable()', () {
    late SyncQueueDatabase db;
    late SyncQueue queue;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      queue = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await queue.ensureLoaded();
    });

    tearDown(() async {
      await queue.dispose();
      await db.close();
    });

    test('MEDIA_UPLOAD not flushable until parent FIELD_REPORT is synced',
        () async {
      final parentId = 'parent-1';
      final draft = FieldReportDraft(
        clientDraftId: parentId,
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
      );
      final mediaRef = DraftMediaRef(
        clientRefId: 'm1',
        localPath: '/tmp/photo.jpg',
      );
      await queue.enqueue(_parentOp(draft, parentId));
      await queue.enqueue(_mediaOp(mediaRef, parentId));

      final flushed = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'FIELD_REPORT', 'MEDIA_UPLOAD'},
        maxOps: 10,
        allowMedia: true,
      );
      final opIds = flushed.map((e) => e.clientOpId).toList();
      expect(opIds, contains(parentId));
      expect(opIds, isNot(contains('m1')));

      await queue.markStatus(
        clientOpId: parentId,
        status: SyncQueueStatus.synced,
        resourceId: 'srv-1',
      );
      final flushed2 = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'FIELD_REPORT', 'MEDIA_UPLOAD'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed2.map((e) => e.clientOpId), contains('m1'));
    });

    test('MEDIA_UPLOAD stays blocked when parent is conflict', () async {
      final parentId = 'parent-c';
      final draft = FieldReportDraft(
        clientDraftId: parentId,
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
      );
      final mediaRef = DraftMediaRef(
        clientRefId: 'm2',
        localPath: '/tmp/p.jpg',
      );
      await queue.enqueue(_parentOp(draft, parentId));
      await queue.enqueue(_mediaOp(mediaRef, parentId));
      await queue.markStatus(
        clientOpId: parentId,
        status: SyncQueueStatus.conflict,
        lastError: 'duplicate',
      );
      final flushed = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'FIELD_REPORT', 'MEDIA_UPLOAD'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed.map((e) => e.clientOpId), isNot(contains('m2')));
    });
  });

  group('Phase 2 - DraftRepository persistence', () {
    late SyncQueueDatabase db;
    late DraftRepository repo;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      repo = DraftRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('save then reload then soft-delete then reload returns nothing',
        () async {
      final draft = FieldReportDraft(
        clientDraftId: 'draft-1',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
      );
      await repo.save(draft);
      expect((await repo.loadAll()).map((d) => d.clientDraftId),
          ['draft-1']);
      await repo.delete('draft-1');
      expect(await repo.loadAll(), isEmpty);
    });

    test('media refs round-trip through save + load', () async {
      final draft = FieldReportDraft(
        clientDraftId: 'draft-2',
        incidentType: 'FLOOD',
        severity: 'HIGH',
        lon: 91,
        lat: 26,
        mediaRefs: [
          DraftMediaRef(
            clientRefId: 'm-1',
            localPath: '/tmp/a.jpg',
            contentType: 'image/jpeg',
            sizeBytes: 1024,
          ),
          DraftMediaRef(
            clientRefId: 'm-2',
            localPath: '/tmp/b.jpg',
            contentType: 'image/jpeg',
            sizeBytes: 2048,
          ),
        ],
      );
      await repo.save(draft);
      final loaded = (await repo.loadAll()).single;
      expect(loaded.mediaRefs, hasLength(2));
      expect(loaded.mediaRefs.first.clientRefId, 'm-1');
      expect(loaded.mediaRefs.last.sizeBytes, 2048);
    });
  });

  group('Phase 2 - MediaQueue persistence', () {
    late SyncQueueDatabase db;
    late MediaQueue media;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      media = MediaQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueue then markUploading then markUploaded lifecycle', () async {
      final ref = DraftMediaRef(
        clientRefId: 'm-1',
        localPath: '/tmp/x.jpg',
      );
      await media.enqueue(ref, 'draft-x');
      var row = (await media.forDraft('draft-x')).single;
      expect(row.state, 'QUEUED');
      await media.markUploading(ref.clientRefId);
      row = (await media.forDraft('draft-x')).single;
      expect(row.state, 'UPLOADING');
      await media.markUploaded(ref.clientRefId, 'srv-media-99');
      row = (await media.forDraft('draft-x')).single;
      expect(row.state, 'UPLOADED');
      expect(row.serverMediaId, 'srv-media-99');
    });

    test('markFailed persists FAILED state', () async {
      final ref = DraftMediaRef(
        clientRefId: 'm-fail',
        localPath: '/tmp/f.jpg',
      );
      await media.enqueue(ref, 'draft-f');
      await media.markFailed(ref.clientRefId);
      final row = (await media.forDraft('draft-f')).single;
      expect(row.state, 'FAILED');
    });
  });

  group('Phase 2 - end-to-end recovery matrix', () {
    test('create offline + attach media + parent syncs -> media uploads',
        () async {
      final db = SyncQueueDatabase.memory();
      final queue = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await queue.ensureLoaded();
      final draftRepo = DraftRepository(db);
      final mediaQueue = MediaQueue(db);

      final fakeService = _FakeFieldReportsService();
      fakeService.nextThrow = const NetworkException('airplane mode');
      final repo = FieldReportsRepository.fromService(
        svc: fakeService,
        draftRepo: draftRepo,
      );
      final draft = FieldReportDraft(
        clientDraftId: 'd-recov',
        incidentType: 'LANDSLIDE',
        severity: 'CRITICAL',
        lon: 91.7,
        lat: 26.1,
        mediaRefs: [
          DraftMediaRef(clientRefId: 'm-recov', localPath: '/tmp/r.jpg'),
        ],
      );
      final result = await repo.submit(draft);
      expect(result, isA<SubmitQueued>());
      await draftRepo.save(draft);

      final parentId = (result as SubmitQueued).entry.clientOpId;
      await queue.enqueue(result.entry);
      for (final ref in draft.mediaRefs) {
        await queue.enqueue(SyncQueueEntry(
          clientOpId: ref.clientRefId,
          opType: 'MEDIA_UPLOAD',
          status: SyncQueueStatus.pending,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          dependencyClientOpId: parentId,
          payload: {'local_path': ref.localPath},
        ));
        await mediaQueue.enqueue(ref, draft.clientDraftId);
      }

      final loadedDraft = await draftRepo.loadById('d-recov');
      expect(loadedDraft, isNotNull);
      expect(loadedDraft!.incidentType, 'LANDSLIDE');

      await queue.markStatus(
        clientOpId: parentId,
        status: SyncQueueStatus.syncing,
      );
      await queue.markStatus(
        clientOpId: parentId,
        status: SyncQueueStatus.synced,
        resourceId: 'srv-recov-1',
      );

      final flushed = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'MEDIA_UPLOAD'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed.single.clientOpId, 'm-recov');

      await mediaQueue.markUploaded('m-recov', 'srv-media-1');
      await queue.markStatus(
        clientOpId: 'm-recov',
        status: SyncQueueStatus.syncing,
      );
      await queue.markStatus(
        clientOpId: 'm-recov',
        status: SyncQueueStatus.synced,
        resourceId: 'srv-media-1',
      );
      await queue.remove('m-recov');

      final entries = queue.entries;
      expect(entries, hasLength(1));
      expect(entries.single.clientOpId, parentId);
      expect(entries.single.status, SyncQueueStatus.synced);
      expect(entries.single.resourceId, 'srv-recov-1');
      expect(
        (await mediaQueue.forDraft(draft.clientDraftId)).single.state,
        'UPLOADED',
      );

      await queue.dispose();
      await db.close();
    });
  });
}

class _FakeFieldReportsService extends FieldReportsService {
  _FakeFieldReportsService() : super(Dio());
  Object? nextThrow;
  String? nextResourceId;

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
    if (nextThrow != null) throw nextThrow!;
    return FieldReport(
      id: nextResourceId ?? 'srv-id',
      incidentType: incidentType,
      severity: severity,
    );
  }
}

