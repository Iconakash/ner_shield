// Phase 6 — persists the offline risk snapshot (§6.1) in the shared Drift
// database so the last server-fused risk survives app kill. The snapshot
// comes from `GET /risk/latest` (the authoritative engine). Nothing here
// recomputes risk — it stores and reloads server rows verbatim and labels
// their age (§6.2).

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/risk_item.dart';
import '../sync/sync_queue_database.dart';
import 'offline_risk.dart';

/// Drift-backed storage of the latest risk snapshot (one row per segment).
class OfflineRiskStore {
  OfflineRiskStore(this._db);

  final SyncQueueDatabase _db;

  /// Replaces the whole snapshot atomically (server truth wins). Rows are
  /// stored verbatim plus the local `fetchedAt` synchronisation instant.
  Future<void> save(
    List<RiskPrediction> predictions, {
    String? districtCode,
    required DateTime fetchedAt,
  }) async {
    await _db.transaction(() async {
      await _db.delete(_db.riskSnapshotRows).go();
      for (final p in predictions) {
        await _db.into(_db.riskSnapshotRows).insert(
          RiskSnapshotRowsCompanion.insert(
            segmentId: p.segmentId,
            districtCode: Value(p.districtCode),
            roadCode: Value(p.roadCode),
            riskCurrent: Value(p.riskCurrent),
            risk6h: Value(p.risk6h),
            risk12h: Value(p.risk12h),
            risk24h: Value(p.risk24h),
            risk72h: Value(p.risk72h),
            overallLabel: Value(p.overallLabel),
            severity: Value(p.severity),
            topFactorsJson: Value(_encodeFactors(p.topFactors)),
            summarySentence: Value(p.summarySentence),
            baseValue: Value(p.baseValue),
            mode: Value(p.mode),
            modelName: Value(p.modelName),
            modelVersion: Value(p.modelVersion),
            computedAt: Value(p.computedAt),
            fetchedAt: fetchedAt.toUtc().toIso8601String(),
          ),
        );
      }
      await _db
          .into(_db.riskSnapshotMetaRows)
          .insertOnConflictUpdate(
            RiskSnapshotMetaRowsCompanion.insert(
              id: const Value('singleton'),
              fetchedAt: fetchedAt.toUtc().toIso8601String(),
              rowCount: Value(predictions.length),
              districtCode: Value(districtCode),
            ),
          );
    });
  }

  /// Loads the persisted snapshot with explicit degradation metadata.
  /// Null when never synchronised. `now` is injectable for tests.
  Future<OfflineRiskResult?> load({
    Duration staleAfter = defaultRiskStaleAfter,
    DateTime? now,
  }) async {
    final meta = await (_db.select(_db.riskSnapshotMetaRows)
          ..where((t) => t.id.equals('singleton')))
        .getSingleOrNull();
    if (meta == null) return null;
    final rows = await (_db.select(_db.riskSnapshotRows)).get();
    final predictions = <RiskPrediction>[];
    for (final r in rows) {
      predictions.add(_toPrediction(r));
    }
    final fetchedAt = DateTime.tryParse(meta.fetchedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return buildOfflineRiskResult(
      predictions: predictions,
      fetchedAt: fetchedAt,
      computedAt: _latestComputedAt(predictions),
      staleAfter: staleAfter,
      now: now,
    );
  }

  /// When the snapshot was last synchronised (null = never).
  Future<DateTime?> lastFetchedAt() async {
    final meta = await (_db.select(_db.riskSnapshotMetaRows)
          ..where((t) => t.id.equals('singleton')))
        .getSingleOrNull();
    if (meta == null) return null;
    return DateTime.tryParse(meta.fetchedAt);
  }

  /// Wipe the snapshot (logout-everywhere hook keeps risk history private).
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.riskSnapshotRows).go();
      await _db.delete(_db.riskSnapshotMetaRows).go();
    });
  }

  // -- mapping --------------------------------------------------------------

  RiskPrediction _toPrediction(RiskSnapshotRow r) {
    return RiskPrediction.fromJson(<String, dynamic>{
      'segment_id': r.segmentId,
      'road_code': r.roadCode,
      'district_code': r.districtCode,
      'risk_current': r.riskCurrent,
      'risk6h': r.risk6h,
      'risk12h': r.risk12h,
      'risk24h': r.risk24h,
      'risk72h': r.risk72h,
      'overall_label': r.overallLabel,
      'severity': r.severity,
      'top_factors': _decodeFactors(r.topFactorsJson),
      'summary_sentence': r.summarySentence,
      'base_value': r.baseValue,
      'mode': r.mode,
      'model_name': r.modelName,
      'model_version': r.modelVersion,
      'computed_at': r.computedAt,
    });
  }

  static DateTime? _latestComputedAt(List<RiskPrediction> predictions) {
    DateTime? latest;
    for (final p in predictions) {
      final t = DateTime.tryParse(p.computedAt ?? '');
      if (t == null) continue;
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  static String? _encodeFactors(List<Map<String, dynamic>>? factors) {
    if (factors == null) return null;
    return jsonEncode(factors);
  }

  static List<Map<String, dynamic>>? _decodeFactors(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List<dynamic>
          ? decoded.whereType<Map<String, dynamic>>().toList()
          : null;
    } catch (_) {
      return null;
    }
  }
}