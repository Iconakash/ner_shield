import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/field_report.dart';

/// "My field reports" list controller — cache-first reads over the backend
/// (`GET /field/reports/mine`).
final myReportsProvider =
    AsyncNotifierProvider<MyReportsController, CachedResult<List<FieldReport>>>(
      MyReportsController.new,
    );

class MyReportsController
    extends AsyncNotifier<CachedResult<List<FieldReport>>> {
  @override
  Future<CachedResult<List<FieldReport>>> build() {
    return ref.watch(fieldReportsRepositoryProvider).mine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fieldReportsRepositoryProvider).mine(),
    );
  }
}

/// Validation queue list controller (`GET /field/reports/queue`).
final reportValidationQueueProvider =
    AsyncNotifierProvider<
      ValidationQueueController,
      CachedResult<List<FieldReport>>
    >(ValidationQueueController.new);

class ValidationQueueController
    extends AsyncNotifier<CachedResult<List<FieldReport>>> {
  @override
  Future<CachedResult<List<FieldReport>>> build() {
    return ref.watch(fieldReportsRepositoryProvider).queue();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fieldReportsRepositoryProvider).queue(),
    );
  }

  /// Verifies or rejects a report. Invalidates the queue cache on success
  /// so the next read reflects the new state.
  Future<FieldReport> validate(
    String id, {
    required String decision,
    String? reason,
  }) {
    return ref
        .read(fieldReportsRepositoryProvider)
        .validate(id, decision: decision, reason: reason);
  }
}

/// Single-report detail controller.
final reportDetailProvider = FutureProvider.family
    .autoDispose<FieldReport, String>((ref, id) async {
      return ref.watch(fieldReportsRepositoryProvider).detail(id);
    });

/// Media list for one report.
final reportMediaProvider = FutureProvider.family
    .autoDispose<List<FieldReportMedia>, String>((ref, id) async {
      return ref.watch(fieldReportsRepositoryProvider).listMedia(id);
    });
