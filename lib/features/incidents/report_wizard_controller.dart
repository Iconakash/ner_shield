import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/validation/offline_draft_validator.dart';
import '../../models/field_report.dart';
import '../../models/sync_queue_entry.dart';
import '../../repositories/field_reports_repository.dart';

/// Wizard step enum — drives the linear flow on the [ReportWizardScreen].
enum ReportWizardStep { incidentType, severity, location, description, review }

extension ReportWizardStepX on ReportWizardStep {
  String get label => switch (this) {
    ReportWizardStep.incidentType => 'Type',
    ReportWizardStep.severity => 'Severity',
    ReportWizardStep.location => 'Location',
    ReportWizardStep.description => 'Description',
    ReportWizardStep.review => 'Review',
  };

  int get index => ReportWizardStep.values.indexOf(this);

  ReportWizardStep? next() {
    final i = index;
    if (i >= ReportWizardStep.values.length - 1) return null;
    return ReportWizardStep.values[i + 1];
  }

  ReportWizardStep? previous() {
    final i = index;
    if (i <= 0) return null;
    return ReportWizardStep.values[i - 1];
  }
}

/// Wizard state — single in-memory draft the officer builds up before submit.
class ReportWizardState {
  const ReportWizardState({
    required this.draft,
    required this.step,
    this.submitting = false,
    this.lastResult,
    this.lastError,
  });

  final FieldReportDraft draft;
  final ReportWizardStep step;
  final bool submitting;

  /// Latest submission outcome (live or queued) — reused from the
  /// repository so there is exactly one SubmitResult vocabulary.
  final SubmitResult? lastResult;

  /// Latest submission error message (server or validation).
  final String? lastError;

  ReportWizardState copyWith({
    FieldReportDraft? draft,
    ReportWizardStep? step,
    bool? submitting,
    SubmitResult? lastResult,
    String? lastError,
    bool clearLastError = false,
  }) {
    return ReportWizardState(
      draft: draft ?? this.draft,
      step: step ?? this.step,
      submitting: submitting ?? this.submitting,
      lastResult: lastResult ?? this.lastResult,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Wizard controller. Owns the in-memory draft, drives step transitions,
/// and submits via the repository (which can transparently queue when
/// offline — master prompt §27).
class ReportWizardController extends Notifier<ReportWizardState> {
  @override
  ReportWizardState build() {
    return ReportWizardState(
      draft: FieldReportsRepository.emptyDraft(),
      step: ReportWizardStep.incidentType,
    );
  }

  void setIncidentType(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        incidentType: value,
        updatedAt: DateTime.now().toIso8601String(),
      ),
      clearLastError: true,
    );
    _persist();
  }

  void setSeverity(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        severity: value,
        updatedAt: DateTime.now().toIso8601String(),
      ),
      clearLastError: true,
    );
    _persist();
  }

  void setDescription(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        description: value,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
    _persist();
  }

  void setLocation({
    required double lon,
    required double lat,
    String? locationName,
    String? stateCode,
    String? districtCode,
    String? segmentId,
    String? roadCode,
  }) {
    final ok = FieldReport.withinBounds(lon: lon, lat: lat);
    if (!ok) {
      state = state.copyWith(
        lastError:
            'Coordinates fall outside the NER region (lon 80-98, lat 21-29.5).',
      );
      return;
    }
    state = state.copyWith(
      draft: state.draft.copyWith(
        lon: lon,
        lat: lat,
        locationName: locationName,
        stateCode: stateCode,
        districtCode: districtCode,
        segmentId: segmentId,
        roadCode: roadCode,
        updatedAt: DateTime.now().toIso8601String(),
      ),
      clearLastError: true,
    );
    _persist();
  }

  /// Phase 2 — attach a media ref to the current draft and saves. The
  /// actual upload bytes remain on disk; only the metadata is persisted
  /// until the parent FIELD_REPORT op reaches `synced` and the upload
  /// worker fires.
  void addMedia(DraftMediaRef ref) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        mediaRefs: [...state.draft.mediaRefs, ref],
        updatedAt: DateTime.now().toIso8601String(),
      ),
      clearLastError: true,
    );
    _persist();
  }

  void removeMedia(String clientRefId) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        mediaRefs: state.draft.mediaRefs
            .where((r) => r.clientRefId != clientRefId)
            .toList(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      clearLastError: true,
    );
    _persist();
  }

  /// Phase 2 — fire-and-forget persistence after every mutation. Failures
  /// are logged but never thrown (we don't want a draft-save bug to
  /// surface as a UI error in the middle of a field officer's flow).
  void _persist() {
    Future<void>.microtask(() async {
      try {
        await ref.read(draftRepositoryProvider).save(state.draft);
      } catch (e, s) {
        AppLogger.instance.error('wizard draft save failed', e, s);
      }
    });
  }

  void goTo(ReportWizardStep step) {
    state = state.copyWith(step: step);
  }

  void next() {
    final n = state.step.next();
    if (n != null) state = state.copyWith(step: n);
  }

  void previous() {
    final p = state.step.previous();
    if (p != null) state = state.copyWith(step: p);
  }

  /// True if the current step has its required fields populated.
  bool get canAdvance {
    switch (state.step) {
      case ReportWizardStep.incidentType:
        return state.draft.incidentType != null;
      case ReportWizardStep.severity:
        return state.draft.severity != null;
      case ReportWizardStep.location:
        return state.draft.lon != null && state.draft.lat != null;
      case ReportWizardStep.description:
        return true; // optional
      case ReportWizardStep.review:
        return state.draft.isComplete;
    }
  }

  /// Submits the draft through the repository. On offline / validation
  /// failure, the draft + its media refs are queued for later flush
  /// (master prompt §27, §28 + §2 media persistence).
  Future<void> submit() async {
    // Phase 2 — fast-fail on client-side validation issues so the user
    // gets immediate feedback without burning a round-trip.
    final offlineError = const OfflineDraftValidator().validate(state.draft);
    if (offlineError != null) {
      state = state.copyWith(lastError: offlineError);
      return;
    }
    if (!state.draft.isComplete) {
      state = state.copyWith(
        lastError: 'Please complete every required field before submitting.',
      );
      return;
    }
    state = state.copyWith(submitting: true, clearLastError: true);
    try {
      final repo = ref.read(fieldReportsRepositoryProvider);
      final queue = ref.read(syncQueueProvider);
      final media = ref.read(mediaQueueProvider);
      final result = await repo.submit(state.draft);
      switch (result) {
        case SubmitLive():
          // Online — server accepted; if the draft had media, queue them.
          await _enqueueMediaForLiveSubmit(state.draft);
          break;
        case SubmitQueued(:final entry):
          // Offline — enqueue the parent FIELD_REPORT op (already built by
          // the repo) plus one MEDIA_UPLOAD op per attached media ref.
          await queue.enqueue(entry);
          final ops = FieldReportsRepository.buildQueueOpsForDraft(state.draft);
          for (final m in ops.media) {
            await queue.enqueue(m);
          }
          for (final ref in state.draft.mediaRefs) {
            await media.enqueue(ref, state.draft.clientDraftId);
          }
      }
      state = state.copyWith(submitting: false, lastResult: result);
    } catch (e, s) {
      // User-facing message only (master prompt 43); full detail goes to the
      // structured log, never to the screen.
      final message = e is AppException
          ? e.message
          : 'Something went wrong while submitting. Please try again.';
      state = state.copyWith(submitting: false, lastError: message);
      AppLogger.instance.error('wizard submit failed', e, s);
    }
  }

  /// Phase 2 — online submit succeeded at the FIELD_REPORT level; queue
  /// each attached media ref for upload against the freshly-issued
  /// server-side report id (recorded by the flush worker after the push
  /// batch returns ACCEPTED).
  Future<void> _enqueueMediaForLiveSubmit(FieldReportDraft draft) async {
    if (draft.mediaRefs.isEmpty) return;
    final queue = ref.read(syncQueueProvider);
    final media = ref.read(mediaQueueProvider);
    for (final ref in draft.mediaRefs) {
      // The parent FIELD_REPORT was accepted live; we still register the
      // media ref so the upload worker can find it. The dependency is
      // satisfied implicitly by the freshly-created live report.
      await media.enqueue(ref, draft.clientDraftId);
      await queue.enqueue(
        SyncQueueEntry(
          clientOpId: ref.clientRefId,
          opType: 'MEDIA_UPLOAD',
          entityType: 'MEDIA',
          status: SyncQueueStatus.pending,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          payload: {
            'local_path': ref.localPath,
            if (ref.contentType != null) 'content_type': ref.contentType,
            if (ref.sizeBytes != null) 'size_bytes': ref.sizeBytes,
            if (ref.sha256 != null) 'sha256': ref.sha256,
          },
        ),
      );
    }
  }

  void reset() {
    final previousId = state.draft.clientDraftId;
    state = ReportWizardState(
      draft: FieldReportsRepository.emptyDraft(),
      step: ReportWizardStep.incidentType,
    );
    // Phase 2 — soft-delete the persisted draft so the next session sees
    // a clean slate.
    Future<void>.microtask(() async {
      try {
        await ref.read(draftRepositoryProvider).delete(previousId);
      } catch (e, s) {
        AppLogger.instance.error('wizard draft delete failed', e, s);
      }
    });
  }
}

final reportWizardProvider =
    NotifierProvider<ReportWizardController, ReportWizardState>(
      ReportWizardController.new,
    );

/// Convenience: list of allowed incident types (matches backend enum).
const kIncidentTypes = <String>[
  'LANDSLIDE',
  'FLOOD',
  'ROAD_DAMAGE',
  'TRAFFIC_BLOCKAGE',
  'BRIDGE_PROBLEM',
  'OTHER',
];

/// Convenience: allowed severities.
const kSeverities = <String>['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
